defmodule LmBackend do
  defdelegate telemetry_received(attrs), to: LmBackend.PubSub
end
