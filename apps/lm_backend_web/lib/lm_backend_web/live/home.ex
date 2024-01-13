defmodule LmBackendWeb.Live.Home do
  use LmBackendWeb, :live_view

  @impl true
  def mount(_param, session, socket) do
    user = session["user"]
    account_id = session["account"].id
    api_key = LmBackend.Accounts.get_api_key(user)

    socket =
      with [_|_] <- LmBackend.Accounts.AgentPresence.list(account_id) do
        # TODO: Add a way to select which dashboard to view
        dashboard = LmBackend.Dashboards.list_dashboards(account_id)
        |> List.first()

        socket
        |> assign(user_id: user.id)
        |> assign(account_id: account_id)
        |> assign(api_key: api_key.key)
        |> assign(dashboard: dashboard)
      else
        [] -> push_navigate(socket, to: ~p"/setup")
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(params, socket) do
    send_update(LmBackendWeb.Components.DashboardContainer, id: "dashboard-container", telemetry: params)
    {:noreply, socket}
  end
end
