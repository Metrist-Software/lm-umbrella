defmodule LmAgent.Statsd.MetricTypes.Set do
  @moduledoc """
  Represents a statsd set

  If a set exist and there haven't been any collection events since the last flush,
  a 0 value will be emitted
  """

  @behaviour LmAgent.Statsd.Metric
  alias LmAgent.Statsd.Metric.StatsdEntry

  @impl true
  def init(%StatsdEntry{ metric: metric, tags: tags }) do
    %{ values: %{}, count: 0, metric: metric, tags: tags }
  end

  @impl true
  def flush(%{values: values, metric: metric, tags: tags, count: count} = state) do
    LmAgent.Statsd.Telemetry.publish_metric(metric, length(Map.keys(values)), tags)
    LmAgent.Statsd.Telemetry.publish_metric("#{metric}_count", count, tags)

    %{ state | values: %{}, count: 0 }
  end

  @doc """
  Process the set.
  """
  @impl true
  def process(%StatsdEntry{value: value}, %{values: values, count: current_count} = state) do
    %{ state |  values: Map.put_new(values, value, 1), count: current_count + 1}
  end
end
