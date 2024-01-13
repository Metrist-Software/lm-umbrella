defmodule LmAgent.Statsd.MetricsWorker do
  use GenServer
  use TypedStruct

  require Logger

  alias LmAgent.Statsd.Metric.StatsdEntry

  @registry :statsd_metric_registry

  typedstruct module: State do
    field :metrics_module, atom() | nil
    field :metric_state, map()
  end

  def start_link([name: name, entry: %StatsdEntry{} = entry]) do
    case LmAgent.Statsd.Metric.find_metric_module_for_entry(entry) do
      nil ->
        :ignore
      metrics_module ->
        GenServer.start_link(__MODULE__, [name: name, metrics_module: metrics_module, initial_entry: entry], name: via_tuple(name))
    end
  end

  @impl true
  def init(args) do
    metrics_module = Keyword.fetch!(args, :metrics_module)
    initial_entry = Keyword.fetch!(args, :initial_entry)
    {:ok, %State{metrics_module: metrics_module, metric_state: metrics_module.init(initial_entry)}}
  end

  def process_metric(name, %StatsdEntry{} = entry) do
    name |> via_tuple() |> GenServer.cast({:process_metric, entry})
  end

  def flush(name) do
    name |> via_tuple() |> GenServer.cast(:flush)
  end

  @impl true
  def handle_cast(:flush, %{ metrics_module: metrics_module, metric_state: metrics_state } = state) do
    {:noreply, %State{ state | metric_state: metrics_module.flush(metrics_state)}}
  end

  @impl true
  def handle_cast({:process_metric, entry}, %{ metrics_module: metrics_module, metric_state: metric_state } = state) do
    new_metrics_state = metrics_module.process(entry, metric_state)
    {:noreply, %State{ state | metric_state: new_metrics_state}}
  end

  defp via_tuple(name),
    do: {:via, Registry, {@registry, name}}
end
