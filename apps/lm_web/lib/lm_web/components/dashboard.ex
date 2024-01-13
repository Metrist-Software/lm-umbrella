defmodule LmWeb.Components.Dashboard do
  use LmWeb, :live_component

  # TODO: Charts currently don't resize with the window. Can't immediately see why, so leaving it as-is for now

  @impl true
  def update(%{telemetry: telemetry}, socket) do
    socket = handle_telemetry(telemetry, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, dashboard: assigns.dashboard, account_id: assigns.account_id, spec_fn: assigns.spec_fn)}
  end

  defp handle_telemetry(telemetry, socket) do
    socket.assigns.dashboard.panels
    |> Enum.filter(& &1.metric == telemetry.metric)
    |> Enum.reduce(socket, fn panel, socket ->
      {event_type, data} = LmWeb.Charts.chart_update_event(telemetry, panel)

      push_event(socket, LmWeb.VegaLiteComponent.event_name(panel.id, event_type), data)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!is_nil(@dashboard)} class="grid grid-cols-6 md:grid-cols-12 gap-4 bg-gray-300 col-span">
        <div
          :for={panel <- @dashboard.panels}
          id={"#{panel.id}-container"}
          class={"col-span-#{panel.width} h-[300px] flex"}
        >
          <.live_component
            module={LmWeb.VegaLiteComponent}
            id={panel.id}
            spec={@spec_fn.(panel, @account_id)} />
        </div>
      </div>
    </div>
    """
  end
end
