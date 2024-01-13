defmodule LmAgent.Statsd.MetricsSupervisor do
  use DynamicSupervisor
  alias LmAgent.Statsd.Metric.StatsdEntry
  alias LmAgent.Statsd.MetricsWorker

  require Logger

  @registry :statsd_metric_registry

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def process_metric(%StatsdEntry{} = entry) do
    case ensure_metrics_process(entry) do
      :ignore -> Logger.info("Statsd - Got unsupported entry: #{inspect entry}. Ignoring")
      name -> MetricsWorker.process_metric(name, entry)
    end
  end

  @doc """
  Flush all registered metrics
  """
  def flush() do
    metrics = Registry.select(@registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    Logger.debug("Statsd - Flushing #{length(metrics)} metric(s).")

    metrics
    |> Enum.map(fn name -> MetricsWorker.flush(name) end)
  end

  def start_metric_server(%StatsdEntry{} = entry) do
    DynamicSupervisor.start_child(__MODULE__, {MetricsWorker, [name: get_name_for_entry(entry), entry: entry]})
  end

  @doc """
  We want a unique genserver per unique set of metric+tags
  """
  def get_name_for_entry(%StatsdEntry{metric: metric, tags: tags}) do
    "#{metric}#{Enum.join(tags, ",")}"
  end

  defp ensure_metrics_process(%StatsdEntry{} = entry) do
    name = get_name_for_entry(entry)
    if Registry.lookup(@registry, name) == [] do
      case start_metric_server(entry) do
        {:ok, _pid} ->
          name
        :ignore ->
          :ignore
      end
    else
      name
    end
  end
end
