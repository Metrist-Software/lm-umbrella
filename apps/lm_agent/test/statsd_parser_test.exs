defmodule StatsdParserTest do
  use ExUnit.Case

  test "values will have leading and trailing spaces parsed out" do
    {:ok, entry} = LmAgent.Statsd.Parser.parse("gorets: test_after space |s")
    assert entry.value == "test_after space"
  end

  test "sampling_rate less than 0.01 will be set to 0.01" do
    {:ok, entry} = LmAgent.Statsd.Parser.parse("gorets: test_after space |s|@0.001")
    assert entry.sampling_rate == 0.01
  end

  test "sampling_rate greater than 1 will be set to 1" do
    {:ok, entry} = LmAgent.Statsd.Parser.parse("gorets: test_after space |s|@1000")
    assert entry.sampling_rate == 1
  end

  test "Tags will be parsed into list" do
    {:ok, entry} = LmAgent.Statsd.Parser.parse("gorets: test_after space |s|@1000|#tag,tag2:tag2value")
    assert length(entry.tags) == 2
    assert hd(entry.tags) == "tag"
  end
end
