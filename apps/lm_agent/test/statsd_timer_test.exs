defmodule StatsdTimerTest do
  use ExUnit.Case

  alias LmAgent.Statsd.MetricTypes.Timer
  alias LmAgent.Statsd.Metric.StatsdEntry

  test "Will init at 0 and empty" do
    metric_state = Timer.init(%StatsdEntry{})
    assert metric_state.values == []
    assert metric_state.count == 0
  end

  test "After flush, values will be empty and count will be 0" do
    metric_state =
      Timer.init(%StatsdEntry{})
      |> Map.put(:values, [5,2])
      |> Map.put(:count, 2)

    metric_state = Timer.flush(metric_state)

    assert metric_state.values == []
    assert metric_state.count == 0
  end

  test "Flush will include all the histogram/timer aggregates plus the total count of events" do
    LmAgent.Statsd.Telemetry.subscribe()
    metric_state =
      Timer.init(%StatsdEntry{ metric: "test_metric"})
      |> Map.put(:values, [6, 3, 9, 6, 6, 9, 9, 9, 9, 9])
      |> Map.put(:count, 10)

    Timer.flush(metric_state)

    assert_received({:statsd_telemetry, "test_metric_min", _ts, 3, _tags})
    assert_received({:statsd_telemetry, "test_metric_max", _ts, 9, _tags})
    assert_received({:statsd_telemetry, "test_metric_mean", _ts, 7.5, _tags})
    assert_received({:statsd_telemetry, "test_metric_median", _ts, 9.0, _tags})
    assert_received({:statsd_telemetry, "test_metric_stddev", _ts, 2.0124611797498106, _tags})
    assert_received({:statsd_telemetry, "test_metric_ninetyfive", _ts, 9, _tags})
    assert_received({:statsd_telemetry, "test_metric_sum", _ts, 75, _tags})
    assert_received({:statsd_telemetry, "test_metric_count", _ts, 10, _tags})
  end
end
