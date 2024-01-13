defmodule LmBackendWeb.DashboardLive.Index do
  use LmBackendWeb, :live_view

  alias LmBackend.Dashboards
  alias LmCommon.Dashboards.{Dashboard, Panel}

  @impl true
  def mount(_params, session, socket) do
    account_id = session["account"].id

    socket = socket
    |> stream(:dashboards, Dashboards.list_dashboards(account_id))
    |> assign(:account_id, account_id)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Dashboard")
    |> assign(:dashboard, Dashboards.get_dashboard!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Dashboard")
    |> assign(:dashboard, %Dashboard{account_id: socket.assigns.account_id, panels: [%Panel{}]})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Dashboards")
    |> assign(:dashboard, nil)
  end

  @impl true
  def handle_info({LmBackendWeb.DashboardLive.FormComponent, {:saved, dashboard}}, socket) do
    {:noreply, stream_insert(socket, :dashboards, dashboard)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    dashboard = Dashboards.get_dashboard!(id)
    {:ok, _} = Dashboards.delete_dashboard(dashboard)

    {:noreply, stream_delete(socket, :dashboards, dashboard)}
  end
end
