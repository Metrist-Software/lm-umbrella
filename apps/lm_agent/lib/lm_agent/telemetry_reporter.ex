defmodule LmAgent.TelemetryReporterSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    children = [
      {Cachex, name: LmAgent.PrometheusMetricCache.cache()},
      {LmAgent.TelemetryReporter, metrics: Keyword.get(arg, :metrics, [])}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule LmAgent.TelemetryReporter do
  use GenServer
  require Logger

  @topic "#{__MODULE__}.telemetry"

  def start_link(args, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def subscribe() do
    unsubscribe()
    Phoenix.PubSub.subscribe(LmCommon.PubSub, @topic)
  end

  def unsubscribe() do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, @topic)
  end

  @impl true
  def init(args) do
    metrics = Keyword.fetch!(args, :metrics)

    for {event, metrics} <- Enum.group_by(metrics, & &1.event_name) do
      id = {__MODULE__, event, self()}
      :telemetry.attach(id, event, &LmAgent.TelemetryReporter.handle_event/4, metrics)
    end

    LmAgent.Statsd.Telemetry.subscribe()

    {:ok, %{}}
  end

  @impl true
  @doc """
  Transforms statsd processed telemetry from our statsd server into Telemetry format then
  broadcast on the existing topic. This way everything else in the pipeline can remain unchanged
  (storage, pushes to backend, etc.)
  Creates a label by appending :statsd to the existing metric name
  """
  def handle_info({:statsd_telemetry, name, ts, value, tags}, state) do
    Phoenix.PubSub.broadcast!(
      LmCommon.PubSub,
      @topic,
      {:telemetry, [:statsd, name], ts, value,
       Map.new(
         tags,
         fn tag ->
           case String.split(tag, ":") do
             [label, value | _] ->
               {label, value}

             [label] ->
               # Statsd supports tags with no values, we need a map, so just assign nil in this case
               {label, nil}
           end
         end
       )}
    )

    {:noreply, state}
  end

  # We handle prometheus metrics differently by appending the prometheus metric name to the event name and using at as
  # the telemetry label for example
  # prom_name: backend_prom_ex_ecto_repo_query_idle_time_milliseconds_count
  # telemetry label: lm.prometheus_prox.backend_prom_ex_ecto_repo_query_idle_time_milliseconds_count
  def handle_event([:lm, :prometheus_proxy] = event_name, measurements, metadata, metrics) do
    for metric <- metrics do
      measurement = extract_measurement(metric, measurements, metadata)
      cache_key = {prom_metric_name, tags} = Map.pop(metric.tag_values.(metadata), "metric_name")

      # Only emit a telemetry if the value has changed
      if LmAgent.PrometheusMetricCache.new_value?(cache_key, measurement) do
        ts = DateTime.utc_now()
        label = event_name ++ [prom_metric_name]

        Phoenix.PubSub.broadcast!(
          LmCommon.PubSub,
          @topic,
          {:telemetry, label, ts, measurement, tags}
        )

        LmAgent.PrometheusMetricCache.put(cache_key, measurement)
      end
    end
  end

  def handle_event(_event_name, measurements, metadata, metrics) do
    for metric <- metrics do
      # We timestamp here which is as close to the actual event as we can get
      ts = DateTime.utc_now()

      Phoenix.PubSub.broadcast!(
        LmCommon.PubSub,
        @topic,
        {:telemetry, metric.name, ts, extract_measurement(metric, measurements, metadata), extract_tags(metric, metadata)}
      )
    end
  end

  defp extract_measurement(metric, measurements, metadata) do
    case metric.measurement do
      fun when is_function(fun, 1) -> fun.(measurements)
      fun when is_function(fun, 2) -> fun.(measurements, metadata)
      key -> measurements[key]
    end
  end

  def extract_tags(metric, metadata) do
    tag_values = metric.tag_values.(metadata)
    Map.take(tag_values, metric.tags)
  end
end
