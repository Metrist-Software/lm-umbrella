defmodule StatsdDictionaryTest do
  use ExUnit.Case

  alias LmAgent.Statsd.MetricTypes.Dictionary
  alias LmAgent.Statsd.Metric.StatsdEntry

  test "Dictionary will init to an empty map" do
    metric_state = Dictionary.init(%StatsdEntry{})
    assert metric_state.values == %{}
    assert metric_state.count == 0
  end

  test "After flush, any existing value keys will be reset to 0" do
    metric_state =
      Dictionary.init(%StatsdEntry{})
      |> Map.put(:values, %{ "user1" => 10})
      |> Map.put(:count, 1)

    metric_state = Dictionary.flush(metric_state)

    assert Map.get(metric_state.values, "user1") == 0
    assert metric_state.count == 0
  end

  test "Duplicate key will increment and sample rate has no effect" do
    metric_state =
      Dictionary.init(%StatsdEntry{})
      |> Map.put(:values, %{ "user1" => 10})
      |> Map.put(:count, 1)

      metric_state = Dictionary.process(%StatsdEntry{ value: "user1", sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 2
    assert Map.get(metric_state.values, "user1") == 11
  end

  test "New key will set to 1" do
    metric_state =
      Dictionary.init(%StatsdEntry{})

    metric_state = Dictionary.process(%StatsdEntry{ value: "user1", sampling_rate: 0.1}, metric_state)
    assert metric_state.count == 1
    assert Map.get(metric_state.values, "user1") == 1
  end

  test "New key when already at max_unique will set other" do
    metric_state =
      Dictionary.init(%StatsdEntry{})
      |> Map.put(:values, for i <- 1..200 do {i, 1} end |> Map.new())

    metric_state = Dictionary.process(%StatsdEntry{ value: "newkey1"}, metric_state)
    metric_state = Dictionary.process(%StatsdEntry{ value: "newkey2"}, metric_state)
    assert Map.get(metric_state.values, "other") == 2
  end

  test "Flush will include the total count for the metric and the count per key" do
    LmAgent.Statsd.Telemetry.subscribe()
    metric_state =
      Dictionary.init(%StatsdEntry{ metric: "test_metric"})
      |> Map.put(:values, %{ "user1" => 10, "user2" => 5})
      |> Map.put(:count, 15)

    Dictionary.flush(metric_state)

    assert_received({:statsd_telemetry, "test_metric_user1", _ts, 10, _tags})
    assert_received({:statsd_telemetry, "test_metric_user2", _ts, 5, _tags})
    assert_received({:statsd_telemetry, "test_metric_count", _ts, 15, _tags})
  end
end
