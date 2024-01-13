defmodule LmBackendTest do
  use ExUnit.Case
  doctest LmBackend

  test "greets the world" do
    assert LmBackend.hello() == :world
  end
end
