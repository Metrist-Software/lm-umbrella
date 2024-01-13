defmodule LmAgent.OsTelemetry do
  require Logger

  def dispatch_os_telem() do
    :disksup.get_disk_data()
    |> Enum.reject(fn {id, _, _} -> id == "none" end)
    |> Enum.each(fn {id, capacity_kb, percent_used} ->
      # Note: These derived numbers likely aren't accurate enough to be useful
      # since percent_used is an integer, so used/free kb will only ever increment
      # in steps of (capacity / 100)kb
      used_kb = (capacity_kb * percent_used) / 100

      :telemetry.execute(
        [:lm, :os, :disk_usage],
        %{
          percent_used: percent_used,
          used_kb: used_kb,
          free_kb: capacity_kb - used_kb,
          capacity_kb: capacity_kb
        },
        %{path: id}
      )
    end)


    memory_data = :memsup.get_system_memory_data()
    |> Keyword.take([:available_memory, :total_memory])
    |> Map.new()

    :telemetry.execute([:lm, :os, :mem_usage], memory_data)
  end
end
