defmodule LmBackend.AgentPresenceUpdater do
  use GenServer
  require Logger

  @flush_interval 60_000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    LmBackend.PubSub.subscribe_telemetry_received()
    schedule_flush()
    {:ok, %{}}
  end

  @impl true
  def handle_info(%{time: dt, account_id: account_id, tags: %{"node" => node}}, state) do
    state = Map.put(state, {account_id, node}, dt)
    {:noreply, state}
  end

  def handle_info(:flush, state) do
    Logger.info("Flush: #{inspect(state)}")

    state
    |> Enum.map(fn {{account_id, node}, dt} ->
      {account_id, node, dt}
    end)
    |> LmBackend.Accounts.AgentPresence.seen_all()

    schedule_flush()

    {:noreply, %{}}
  end

  def handle_info(msg, state) do
    Logger.info("Unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval)
  end
end
