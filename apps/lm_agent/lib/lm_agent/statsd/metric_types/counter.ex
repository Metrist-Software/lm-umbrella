defmodule LmAgent.Statsd.MetricTypes.Counter do
  @moduledoc """
  Represents a statsd counter

  Meter is an alias for counter

  A metric can be sent without a type and/or without a value in that case the metric will be assumed to be a
  +1 to the counter by that name

  If a counter exist and there haven't been any collection events since the last flush,
  a 0 value will be emitted

  Counters reset to 0 on every flush

  This metric type supports sampling rate
  """

  @behaviour LmAgent.Statsd.Metric
  alias LmAgent.Statsd.Metric.StatsdEntry

  require Logger

  @impl true
  def init(%StatsdEntry{ metric: metric, tags: tags }) do
    %{ value: 0, count: 0, metric: metric, tags: tags }
  end

  @doc """
  Counters reset on flush
  """
  @impl true
  def flush(%{value: value, metric: metric, tags: tags} = state) do
    LmAgent.Statsd.Telemetry.publish_metric(metric, value, tags)
    %{ state| value: 0, count: 0 }
  end

  @impl true
  def process(%StatsdEntry{value: nil}, %{value: current_value, count: count} = state) do
    %{ state |  value: current_value + 1, count: count + 1}
  end
  def process(%StatsdEntry{value: value, sampling_rate: sampling_rate}, %{value: current_value, count: count, metric: metric} = state) do
      with {float_value, _rem} <- Float.parse(value) do
        %{ state |  value: current_value + (Float.floor(float_value / sampling_rate)), count: count + 1}
      else
        :error ->
          Logger.warn("Statsd - Invalid value passed for metric #{metric}. Value was #{value}")
      end
  end
end
