defmodule LmAgent.Statsd.MetricTypes.Dictionary do
  @moduledoc """
  Represents a statsd dictionary

  If a value exist in the dictionary and we haven't received anything since the last flush, we will report 0 for that value.

  This type will accept the configured dictionary max unique dimensions unique values to stop it from growing indefinitely
  as keys are held through flushes. After the max_unique value has been hit, all metrics will be stored against "other".
  The max unique value defaults to 200 and can be configured with the LM_STATSD_DICTIONARY_MAX_UNIQUE_DIMENSIONS
  environment variable

  Count will always be to total number of received events for that flush interval.
  """

  @behaviour LmAgent.Statsd.Metric
  alias LmAgent.Statsd.Metric.StatsdEntry

  require Logger

  @impl true
  def init(%StatsdEntry{ metric: metric, tags: tags }) do
    max_unique =
      Application.fetch_env!(:lm_agent, LmAgent.Statsd.Server)
      |> Keyword.get(:dictionary_max_unique_dimensions, 200)

    %{ values: %{}, count: 0, metric: metric, tags: tags, max_unique_dimensions: max_unique }
  end

  @impl true
  def flush(%{values: values, metric: metric, tags: tags, count: total_update_for_metric, max_unique_dimensions: max_unique} = state) do
    reset_values =
      values
      |> Enum.map(fn {key, count} ->
        LmAgent.Statsd.Telemetry.publish_metric("#{metric}_#{key}", count, tags)
        LmAgent.Statsd.Telemetry.publish_metric("#{metric}_count", total_update_for_metric, tags)
        {key, 0}
      end)
      |> Map.new()

    if map_size(values) > max_unique do
      Logger.warn("#{metric} has hit the max unique values of #{max_unique}. Consider increasing the allowed max_unique value with LM_STATSD_DICTIONARY_MAX_UNIQUE_DIMENSIONS")
    end

    %{ state | values: reset_values, count: 0 }
  end

  @doc """
  Process the gauge.
  """
  @impl true
  def process(%StatsdEntry{}, %{values: values, count: current_count, max_unique_dimensions: max_unique } = state) when map_size(values) >= max_unique do
    current_value = Map.get(values, "other", 0)
    %{ state |  values: Map.put(values, "other", current_value + 1), count: current_count + 1}
  end
  def process(%StatsdEntry{value: value}, %{values: values, count: current_count } = state) do
    current_value = Map.get(values, value, 0)
    %{ state |  values: Map.put(values, value, current_value + 1), count: current_count + 1}
  end
end
