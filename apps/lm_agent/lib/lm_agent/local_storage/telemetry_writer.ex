defmodule LmAgent.LocalStorage.TelemetryWriter do
  @moduledoc """
  GenServer that subscribes to telemetry updates and writes them. Very simple for now, we
  could ask tasks-per-write, batch writes, close files after not being used for while,
  and so on, but for now this should fulfill the goal of "local metrics storage".

  Note that the server keeps open file handles. Concurrent reading
  """
  use GenServer

  defmodule State do
    defstruct [
      data_dir: nil,
      files: %{}]
  end

  def start_link([]) do
    start_link(LmAgent.data_dir())
  end

  def start_link(data_dir) do
    name = make_name(data_dir)
    GenServer.start_link(__MODULE__, [data_dir], name: name)
  end

  # Server side

  @impl true
  def init([data_dir]) do
    LmAgent.TelemetryReporter.subscribe()
    {:ok, %State{data_dir: data_dir}}
  end

  @impl true
  def handle_info({:telemetry, name, ts, value, tags} = _telem, state) do
    {state, file} = get_file(state, name, ts)
    LmAgent.LocalStorage.write(file, ts, value, tags)
    {:noreply, state}
  end

  # Private
  #
  defp get_file(state, name, ts) do
    day = LmCommon.day_num(ts)
    if Map.has_key?(state.files, name) do
      {file_day, file} = Map.get(state.files, name)
      if file_day == day do
        # Today, all good.
        {state, file}
      else
        # Old day. Close file, try again
        LmAgent.LocalStorage.close(file)
        state = %State{state | files: Map.delete(state.files, name)}
        get_file(state, name, ts)
      end
    else
      # New file
      file = LmAgent.LocalStorage.open_for_write(state.data_dir, name, day)
      state = %State{state | files: Map.put(state.files, name, {day, file})}
      {state, file}
    end
  end

  defp make_name(data_dir) do
    String.to_atom("#{__MODULE__}:#{data_dir}")
  end
 end
