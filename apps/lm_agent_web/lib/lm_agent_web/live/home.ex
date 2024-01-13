defmodule LmAgentWeb.Live.Home do
  use LmAgentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do

    socket = socket
    |> assign(dashboard: LmAgent.Dashboards.get())

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:telemetry, name, ts, value, tags}, socket) do
    # TODO: Need to move to a different telemetry format
    # LmWeb can't use LmBackend.Telemetry.TelemetryEntry, and it doesn't make sense
    # to use an aggregated representation here when we only need  ts, value, and tags
    telem = %{time: ts, metric: Enum.join(name, "."), avg: value, tags: tags}
    send_update(LmAgentWeb.Components.DashboardContainer, id: "dashboard-container", telemetry: telem)

    {:noreply, socket}
  end

  def handle_info({LmAgentWeb.DashboardLive.FormComponent, {:saved, dashboard}}, socket) do
    {:noreply, assign(socket, dashboard: dashboard)}
  end

  @impl true
  def handle_event("edit_dashboard", _params, socket) do
    {:noreply, socket}
  end
end
