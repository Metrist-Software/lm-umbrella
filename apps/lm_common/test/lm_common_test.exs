defmodule LmCommonTest do
  use ExUnit.Case
  doctest LmCommon

  test "greets the world" do
    assert LmCommon.hello() == :world
  end
end
