defmodule LmBackend.PubSub do
  @moduledoc """
  PubSub helper functions for the backend.
  """

  @doc """
  Telemetry received notification. See `LmBackendWeb.Controllers.TelemetryController` for
  message format.
  """
  def telemetry_received(attrs) do
    Phoenix.PubSub.broadcast(LmCommon.PubSub, topic(attrs.account_id, attrs.metric), attrs)
    Phoenix.PubSub.broadcast(LmCommon.PubSub, topic(), attrs)
  end

  def realtime_telemetry_received(attrs) do
    Phoenix.PubSub.broadcast(LmCommon.PubSub, realtime_topic(attrs.account_id), attrs)
  end

  def agent_presence(presence=%LmBackend.Accounts.AgentPresence{}) do
    Phoenix.PubSub.broadcast(LmCommon.PubSub, presence_topic(presence.account_id), {:agent_presence, presence})
  end

  def subscribe_telemetry_received() do
    unsubscribe_telemetry_received()
    Phoenix.PubSub.subscribe(LmCommon.PubSub, topic())
  end

  def subscribe_telemetry_received(account_id, metric) do
    unsubscribe_telemetry_received(account_id, metric)
    Phoenix.PubSub.subscribe(LmCommon.PubSub, topic(account_id, metric))
  end

  def subscribe_agent_presence(account_id) do
    unsubscribe_agent_presence(account_id)
    Phoenix.PubSub.subscribe(LmCommon.PubSub, presence_topic(account_id))
  end

  def unsubscribe_agent_presence(account_id) do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, presence_topic(account_id))
  end

  def unsubscribe_telemetry_received() do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, topic())
  end

  def unsubscribe_telemetry_received(account_id, metric) do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, topic(account_id, metric))
  end

  def subscribe_realtime_telemetry(account_id) do
    unsubscribe_realtime_telemetry(account_id)
    Phoenix.PubSub.subscribe(LmCommon.PubSub, realtime_topic(account_id))
  end

  def unsubscribe_realtime_telemetry(account_id) do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, realtime_topic(account_id))
  end

  defp topic(), do: "telemetry_received"

  defp topic(account_id, metric) do
    "telemetry_received:#{account_id}:#{metric}"
  end

  defp presence_topic(account_id) do
    "agent_presence:#{account_id}"
  end

  defp realtime_topic(account_id) do
    "realtime_telemetry_received:#{account_id}"
  end
end
