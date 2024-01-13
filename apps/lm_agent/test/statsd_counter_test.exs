defmodule StatsdCounterTest do
  use ExUnit.Case

  alias LmAgent.Statsd.MetricTypes.Counter
  alias LmAgent.Statsd.Metric.StatsdEntry

  test "Counter will init at 0" do
    metric_state = Counter.init(%StatsdEntry{})
    assert metric_state.value == 0
    assert metric_state.count == 0
  end

  test "After flush, count and value will reset to 0" do
    metric_state =
      Counter.init(%StatsdEntry{})
      |> Map.put(:value, 5)
      |> Map.put(:count, 5)

    metric_state = Counter.flush(metric_state)

    assert metric_state.value == 0
    assert metric_state.count == 0
  end

  test "Sampling rate applies" do
    metric_state =
      Counter.init(%StatsdEntry{})

      metric_state = Counter.process(%StatsdEntry{ value: "1", sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 1
    assert metric_state.value == 10
  end

  test "nil value increments by 1 and sampling rate is ignored" do
    metric_state =
      Counter.init(%StatsdEntry{})

      metric_state = Counter.process(%StatsdEntry{ value: nil, sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 1
    assert metric_state.value == 1
  end

  test "Flush will include only the current value of the counter" do
    LmAgent.Statsd.Telemetry.subscribe()
    metric_state =
      Counter.init(%StatsdEntry{ metric: "test_metric"})
      |> Map.put(:value, 10)
      |> Map.put(:count, 5)

    Counter.flush(metric_state)

    assert_received({:statsd_telemetry, "test_metric", _ts, 10, _tags})
  end
end
