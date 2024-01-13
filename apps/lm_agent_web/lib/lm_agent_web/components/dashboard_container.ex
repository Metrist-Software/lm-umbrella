defmodule LmAgentWeb.Components.DashboardContainer do
  use LmAgentWeb, :live_component

  @impl true
  def update(%{telemetry: telemetry}, socket) do
    send_update(LmWeb.Components.Dashboard, id: "dashboard", telemetry: telemetry)

    {:ok, socket}
  end

  def update(assigns, socket) do
    LmAgent.TelemetryReporter.subscribe()

    {:ok,
     assign(socket,
       dashboard: assigns.dashboard,
       spec_fn: &get_spec/2
     )}
  end

  def get_spec(panel, _account_id) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -1, :day)

    start_day_num = LmCommon.day_num(start_time)
    end_day_num = LmCommon.day_num(end_time)

    name = String.split(panel.metric, ".")

    data = start_day_num..end_day_num
    |> Enum.map(& read_telemetry(name, &1))
    |> List.flatten()
    |> Enum.reject(fn {ts, _value, _tags} -> DateTime.compare(ts, start_time) == :lt || DateTime.compare(ts, end_time) == :gt end)
    |> Enum.group_by(
      fn {_ts, _value, tags} -> tags end,
      fn {ts, value, _tags} -> %{ts => %{avg: value}} end
    )
    |> Enum.map(fn {tag, entries} ->
      entries = Enum.reduce(entries, %{}, fn entry, acc -> Map.merge(acc, entry) end)
      {tag, entries}
    end)
    |> Map.new()

    LmWeb.Charts.chart(panel, data)
  end

  defp read_telemetry(name, day) do
    file = LmAgent.LocalStorage.open_for_read(LmAgent.data_dir(), name, day)
    data = read_lines(file)
    LmAgent.LocalStorage.close(file)
    data
  end

  defp read_lines(nil), do: []
  defp read_lines(file), do: read_lines(file, [])
  defp read_lines(file, acc) do
    case LmAgent.LocalStorage.read(file) do
      nil -> acc
      line -> read_lines(file, [line | acc])
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!is_nil(@dashboard)}>
        <.live_component
          id="dashboard"
          module={LmWeb.Components.Dashboard}
          dashboard={@dashboard}
          account_id={nil}
          spec_fn={@spec_fn}
        />
      </div>
    </div>
    """
  end
end
