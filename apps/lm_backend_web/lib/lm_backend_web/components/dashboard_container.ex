defmodule LmBackendWeb.Components.DashboardContainer do
  use LmBackendWeb, :live_component

  @impl true
  def update(%{telemetry: telemetry}, socket) do
    send_update(LmWeb.Components.Dashboard, id: "dashboard", telemetry: telemetry)

    {:ok, socket}
  end

  def update(assigns, socket) do
    subscribe_dashboard_metrics(assigns.dashboard, assigns.account_id)

    {:ok,
     assign(socket,
       dashboard: assigns.dashboard,
       account_id: assigns.account_id,
       streaming?: false,
       spec_fn: &get_spec/2
     )}
  end

  defp subscribe_dashboard_metrics(%{panels: panels}, account_id) when is_list(panels) do
    unique_metrics =
      panels
      |> Enum.map(& &1.metric)
      |> Enum.uniq()

    for metric <- unique_metrics do
      LmBackend.PubSub.subscribe_telemetry_received(account_id, metric)
    end
  end

  defp subscribe_dashboard_metrics(_, _), do: []

  defp unsubscribe_dashboard_metrics(%{panels: panels}, account_id) when is_list(panels) do
    unique_metrics =
      panels
      |> Enum.map(& &1.metric)
      |> Enum.uniq()

    for metric <- unique_metrics do
      LmBackend.PubSub.unsubscribe_telemetry_received(account_id, metric)
    end
  end

  defp unsubscribe_dashboard_metrics(_, _), do: []

  def get_spec(panel, account_id) do
    # TODO: Move logic into db query
    data =
      LmBackend.Telemetry.get_data(panel.metric, account_id)
      |> Enum.group_by(
        fn entry -> entry.tags end,
        fn entry -> %{entry.time => %{avg: entry.avg}} end
      )
      |> Enum.map(fn {tag, entries} ->
        entries = Enum.reduce(entries, %{}, fn entry, acc -> Map.merge(acc, entry) end)
        {tag, entries}
      end)
      |> Map.new()

    LmWeb.Charts.chart(panel, data)
  end

  @impl true
  def handle_event("start_stream", _, socket) do
    account_id = socket.assigns.account_id

    unsubscribe_dashboard_metrics(socket.assigns.dashboard, account_id)
    LmBackend.PubSub.subscribe_realtime_telemetry(account_id)
    LmBackendWeb.DataStreamManager.request_stream(self(), account_id)

    {:noreply, assign(socket, :streaming?, true)}
  end

  def handle_event("stop_stream", _, socket) do
    account_id = socket.assigns.account_id

    subscribe_dashboard_metrics(socket.assigns.dashboard, account_id)
    LmBackend.PubSub.unsubscribe_realtime_telemetry(account_id)
    LmBackendWeb.DataStreamManager.stop_stream(self(), account_id)

    {:noreply, assign(socket, :streaming?, false)}
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
          account_id={@account_id}
          spec_fn={@spec_fn}
        />

        <.button :if={not @streaming?} phx-target={@myself} phx-click="start_stream">
          Stream Data
        </.button>
        <.button :if={@streaming?} phx-target={@myself} phx-click="stop_stream">
          Stop Streaming
        </.button>
      </div>
      <div :if={is_nil(@dashboard)}>
        No dashboards found.
        <.link navigate={~p"/dashboards/new"}>
          <.button>Configure</.button>
        </.link>
      </div>
    </div>
    """
  end
end
