defmodule LmAgent.Statsd.MetricTypes.Timer do
  @moduledoc """
  Represents a statsd Timer.

  Histogram is an alias for timer

  Will emit 0 for all metrics when no events have been seen for the metric within this flush interval.

  This metric supports sampling rate
  """

  @behaviour LmAgent.Statsd.Metric
  alias LmAgent.Statsd.Metric.StatsdEntry

  require Logger

  @impl true
  def init(%StatsdEntry{ metric: metric, tags: tags }) do
    %{ values: [], count: 0, metric: metric, tags: tags }
  end

  @impl true
  # We are going to send a 0 value
  # Could implement deleteHistograms/deleteTimers to send nothing in that case
  # and create a gap. Could be configurable later.
  def flush(%{values: [], count: 0} = state), do: flush(%{state | values: [0]})
  def flush(%{values: values, metric: metric, tags: tags, count: count} = state) do
    sorted = Enum.sort(values)
    %{
      min: List.first(sorted),
      max: List.last(sorted),
      mean: mean(values),
      median: median(values),
      stddev: stddev(values),
      ninetyfive: percentile(values, 95),
      sum: Enum.sum(sorted),
      count: count
    }
    |> Enum.each(fn {key, value} ->
      LmAgent.Statsd.Telemetry.publish_metric("#{metric}_#{key}", value, tags)
    end)

    %{ state | values: [], count: 0 }
  end

  @impl true
  def process(%StatsdEntry{value: value, sampling_rate: sampling_rate, metric: metric}, %{count: current_count, values: values} = state) do
    with {float_value, _rem} <- Float.parse(value) do
      samples =
        floor(1 / sampling_rate)

      new_samples = List.duplicate(float_value, samples)

      %{ state | values: values ++ new_samples, count: current_count + 1}
    else
      :error ->
        Logger.warn("Statsd - Invalid value passed for metric #{metric}. Value was #{value}")
    end
  end

  defp percentile([], _), do: nil
  defp percentile(data, percentile) do
    index = Float.floor(length(data) * percentile / 100.0)
    if index < 1 do
      Enum.at(data, 0)
    else
      Enum.at(data, trunc(index - 1))
    end
  end

  defp stddev([]), do: nil
  defp stddev(data) do
    mean = mean(data)
    data |> variance(mean) |> mean |> :math.sqrt
  end

  defp mean([]), do: nil
  defp mean(data) do
    Enum.sum(data) / length(data)
  end

  defp median([]), do: nil
  defp median(data) when length(data) == 1, do: Enum.at(data, 0)
  defp median(data) when length(data) == 2, do: Enum.sum(data) / 2
  defp median(data) when rem(length(data), 2) == 0 do
    middle = trunc(length(data) / 2)
    (Enum.at(data, middle) + Enum.at(data, middle+1)) / 2
  end
  defp median(data), do: Enum.at(data, trunc(length(data)/2))

  defp variance(data, mean) do
    for n <- data, do: :math.pow(n - mean, 2)
  end
end
