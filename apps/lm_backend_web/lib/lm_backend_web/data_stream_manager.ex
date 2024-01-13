defmodule LmBackendWeb.DataStreamManager do
  @moduledoc """
  Monitors active data streaming requests to manage the starting and stopping of
  the actual streaming
  """
  use GenServer
  require Logger

  # Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def request_stream(requester_pid, account_id) do
    pid = GenServer.whereis(__MODULE__)

    GenServer.cast(pid, {:monitor, requester_pid, account_id})
  end

  def stop_stream(requestor_pid, account_id) do
    pid = GenServer.whereis(__MODULE__)

    GenServer.cast(pid, {:demonitor, requestor_pid, account_id})
  end

  # Server

  @impl true
  def init(_opts) do
    state = %{
      by_pid: %{},
      by_account: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:monitor, pid, account_id}, state) do
    ref = Process.monitor(pid)

    pid_list = if Map.has_key?(state.by_account, account_id) do
      [pid | Map.get(state.by_account, account_id, [])]
    else
      LmBackendWeb.Endpoint.broadcast("telemetry:#{account_id}", "start_stream", %{})

      [pid]
    end

    state = state
    |> put_in([:by_account, account_id], pid_list)
    |> put_in([:by_pid, pid], {account_id, ref})

    {:noreply, state}
  end

  def handle_cast({:demonitor, pid, account_id}, state) do
    case state.by_pid[pid] do
      {_account_id, ref} -> Process.demonitor(ref)
      _ -> true
    end

    {:noreply, remove_monitored_pid(state, pid, account_id)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {account_id, _ref} = state.by_pid[pid]

    {:noreply, remove_monitored_pid(state, pid, account_id)}
  end

  defp remove_monitored_pid(state, pid, account_id) when is_nil(pid) or is_nil(account_id), do: state
  defp remove_monitored_pid(state, pid, account_id) do
    state = state
    |> put_in([:by_account, account_id], Map.get(state.by_account, account_id, []) -- [pid])
    |> Map.put(:by_pid, Map.delete(state.by_pid, pid))

    if Enum.empty?(Map.get(state.by_account, account_id, [])) do
      # This was the last active stream request. Stop streaming the telemetry
      # and cleanup the state
      LmBackendWeb.Endpoint.broadcast("telemetry:#{account_id}", "stop_stream", %{})

      Map.put(state, :by_account, Map.delete(state.by_account, account_id))
    else
      state
    end
  end
end
