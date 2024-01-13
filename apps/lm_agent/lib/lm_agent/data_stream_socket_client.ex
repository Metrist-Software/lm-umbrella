defmodule LmAgent.DataStreamSocketClient do
  use Slipstream

  require Logger

  def start_link(args) do
    Slipstream.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    config = Application.fetch_env!(:lm_agent, __MODULE__)
    if config[:enabled] do
      connect(config[:socket_opts])
    else
      :ignore
    end
  end

  @impl true
  def handle_connect(socket) do
    socket = join(socket, topic(), %{api_key: LmAgent.api_key()})

    {:ok, socket}
  end

  @impl true
  def handle_topic_close(_topic, {:failed_to_join, reason}, socket) do
    Logger.error("Failed to join topic. Reason: #{inspect reason}")

    {:ok, socket}
  end
  def handle_topic_close(topic, _reason, socket) do
    rejoin(socket, topic)
  end

  @impl true
  def handle_message(_topic, "start_stream", _, socket) do
    LmAgent.TelemetryReporter.subscribe()
    {:ok, socket}
  end

  def handle_message(_topic, "stop_stream", _, socket) do
    LmAgent.TelemetryReporter.unsubscribe()
    {:ok, socket}
  end

  def handle_message(topic, event, message, socket) do
    Logger.error(
      "Was not expecting a push from the server. Heard: " <>
        inspect({topic, event, message})
    )

    {:ok, socket}
  end

  @impl true
  def handle_info({:telemetry, metric, ts, value, tags}, socket) do
    push(socket, topic(), "telemetry", %{metric: metric, value: value, tags: tags, time: ts, node_name: LmAgent.agent_id()})

    {:noreply, socket}
  end

  @impl true
  def handle_disconnect(reason, socket) do
    case reason do
      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        Logger.info("Could not connect to backend. Retrying...")
        case reconnect(socket) do
          {:ok, socket} -> {:ok, socket}
          {:error, reason} -> {:stop, reason, socket}
        end
      {:error, reason} ->
        {:stop, reason, socket}
      reason ->
        {:stop, reason, socket}
    end
  end

  defp topic(), do: "telemetry:#{LmAgent.account_id()}"
end
