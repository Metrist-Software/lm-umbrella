defmodule LmAgent.Statsd.MetricTypes.Gauge do
  @moduledoc """
  Represents a statsd gauge

  If a gauge exist and there haven't been any collection events since the last flush,
  the last value will be shown until another collection event changes the gauge

  This metric supports sampling rate when passing a differential only

  Due to the nature of including a sign making this a differential, the only way to set a strictly negative number
  is to send a negative diff.
  """

  @behaviour LmAgent.Statsd.Metric
  alias LmAgent.Statsd.Metric.StatsdEntry

  require Logger

  @impl true
  def init(%StatsdEntry{ metric: metric, tags: tags }) do
    %{ last: nil, value: 0, count: 0, metric: metric, tags: tags }
  end

  @impl true
  def flush(%{value: value, metric: metric, tags: tags} = state) do
    LmAgent.Statsd.Telemetry.publish_metric(metric, value, tags)
    # We don't reset value here so that it persist through flushes but we do reset count
    %{ state | last: value, count: 0 }
  end

  @doc """
  Process the gauge.

  If we have a diff operator we are always going to be adding/subtracting from the current value otherwise just set it
  """
  @impl true
  def process(%StatsdEntry{value: <<"-", _number_part::binary>> = value, sampling_rate: sampling_rate}, state) do
    process_diff(value, sampling_rate, state)
  end
  def process(%StatsdEntry{value: <<"+", number_part::binary>>, sampling_rate: sampling_rate}, state) do
    process_diff(number_part, sampling_rate, state)
  end
  def process(%StatsdEntry{value: value}, %{metric: metric, count: count} = state) do
    with {float_value, _rest} <- Float.parse(value) do
      %{ state |  value: float_value, count: count + 1}
    else
      :error ->
        Logger.warn("Statsd - Invalid value passed for metric #{metric}. Value was #{value}")
    end
  end

  defp process_diff(value, sampling_rate, %{value: current_value, metric: metric, count: count} = state) do
    with {float_value, _rest} <- Float.parse(value) do
      %{ state |  value: current_value + (float_value / sampling_rate), count: count + 1}
    else
      :error ->
        Logger.warn("Statsd - Invalid value passed for metric #{metric}. Value was #{value}")
    end
  end
end
