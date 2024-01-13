defmodule StatsdSetTest do
  use ExUnit.Case

  alias LmAgent.Statsd.MetricTypes.Set
  alias LmAgent.Statsd.Metric.StatsdEntry

  test "Set will init to an empty map" do
    metric_state = Set.init(%StatsdEntry{})
    assert metric_state.values == %{}
    assert metric_state.count == 0
  end

  test "After flush, count will reset and list will be empty" do
    metric_state =
      Set.init(%StatsdEntry{})
      |> Map.put(:values, %{ 5 => 1, 10 => 1 })
      |> Map.put(:count, 2)

    metric_state = Set.flush(metric_state)

    assert metric_state.values == %{}
    assert metric_state.count == 0
  end

  test "Duplicate key will not be added but total count will increase" do
    metric_state =
      Set.init(%StatsdEntry{})
      |> Map.put(:values, %{ 5 => 1, 10 => 1 })
      |> Map.put(:count, 2)

      metric_state = Set.process(%StatsdEntry{ value: 10, sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 3
    assert metric_state.values == %{ 5 => 1, 10 => 1 }
  end

  test "New key will be added" do
    metric_state =
      Set.init(%StatsdEntry{})
      |> Map.put(:values, %{ 5 => 1, 10 => 1 })
      |> Map.put(:count, 2)

      metric_state = Set.process(%StatsdEntry{ value: 9, sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 3
    assert metric_state.values == %{ 5 => 1, 10 => 1, 9 => 1 }
  end

  test "Flush will include total count for metric and number of unique keys" do
    LmAgent.Statsd.Telemetry.subscribe()
    metric_state =
      Set.init(%StatsdEntry{ metric: "test_metric"})
      |> Map.put(:values, %{ 5 => 1, 10 => 1 })
      |> Map.put(:count, 5)

    Set.flush(metric_state)

    assert_received({:statsd_telemetry, "test_metric", _ts, 2, _tags})
    assert_received({:statsd_telemetry, "test_metric_count", _ts, 5, _tags})
  end
end
