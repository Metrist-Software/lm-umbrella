defmodule StatsdGaugeTest do
  use ExUnit.Case

  alias LmAgent.Statsd.MetricTypes.Gauge
  alias LmAgent.Statsd.Metric.StatsdEntry

  test "Counter will init at 0 with last as nil" do
    metric_state = Gauge.init(%StatsdEntry{})
    assert metric_state.value == 0
    assert metric_state.count == 0
    assert metric_state.last == nil
  end

  test "After flush, count will reset, but value will remain. Last will be set to value" do
    metric_state =
      Gauge.init(%StatsdEntry{})
      |> Map.put(:value, 5)
      |> Map.put(:count, 5)

    metric_state = Gauge.flush(metric_state)

    assert metric_state.value == 5
    assert metric_state.last == 5
    assert metric_state.count == 0
  end

  test "Setting value without a differential operator. Sampling rate ignored" do
    metric_state =
      Gauge.init(%StatsdEntry{})

    metric_state = Gauge.process(%StatsdEntry{ value: "10", sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 1
    assert metric_state.value == 10
  end

  test "positive differential works" do
    metric_state =
      Gauge.init(%StatsdEntry{})
      |> Map.put(:value, 5)
      |> Map.put(:count, 1)

      metric_state = Gauge.process(%StatsdEntry{ value: "+5", sampling_rate: 0.5}, metric_state)
    assert metric_state.count == 2
    assert metric_state.value == 15
  end

  test "negative differential works" do
    metric_state =
      Gauge.init(%StatsdEntry{})
      |> Map.put(:value, 5)
      |> Map.put(:count, 1)

    metric_state = Gauge.process(%StatsdEntry{ value: "-5", sampling_rate: 0.5}, metric_state)
    assert metric_state.count == 2
    assert metric_state.value == -5
  end

  test "Flush with no values will return the last value" do
    LmAgent.Statsd.Telemetry.subscribe()
    metric_state =
      Gauge.init(%StatsdEntry{ metric: "test_metric"})
      |> Map.put(:value, 10)
      |> Map.put(:count, 0)

    Gauge.flush(metric_state)

    assert_received({:statsd_telemetry, "test_metric", _ts, 10, _tags})
  end
end
