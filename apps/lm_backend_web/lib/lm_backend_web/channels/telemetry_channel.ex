defmodule LmBackendWeb.TelemetryChannel do
  use LmBackendWeb, :channel

  require Logger

  @impl true
  def join("telemetry:" <> account_id, payload, socket) do
    if authorized?(account_id, payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("telemetry", %{"metric" => metric, "tags" => tags, "value" => value, "time" => time, "node_name" => node_name}, socket) do
    "telemetry:" <> account_id = socket.topic

    telemetry_entry = %LmBackend.Telemetry.TelemetryEntry{
      time: time,
      account_id: account_id,
      metric: Enum.join(metric, "."),
      last: value,
      avg: value,
      min: value,
      max: value,
      count: 1,
      tags: Map.put(tags, "node", node_name)
    }

    LmBackend.PubSub.realtime_telemetry_received(telemetry_entry)

    {:noreply, socket}
  end

  def handle_in(event, _payload, socket) do
    Logger.warn("Unexpected event: #{event}")
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_account_id, %{"api_key" => nil}) do
    false
  end

  defp authorized?(account_id, %{"api_key" => api_key}) do
    case LmBackend.Accounts.get_owner(api_key) do
      nil ->
        false
      %LmBackend.Accounts.User{} = user ->
        account_ids = LmBackend.Accounts.account_ids_for(user)

        account_id in account_ids
    end
  end
  defp authorized?(_, _), do: false
end
