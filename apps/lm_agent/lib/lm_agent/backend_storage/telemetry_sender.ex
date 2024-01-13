defmodule LmAgent.BackendStorage.TelemetrySender do
  use GenServer

  alias LmCommon.TelemetryData

  defmodule State do
    defstruct metrics: %{}

    @type telemetry_bucket :: %{optional(DateTime.t()) => TelemetryData.t()}
    @type tag_key :: map()
    @type metric_key :: list(atom())
    @type metric_value :: %{optional(tag_key) => list(telemetry_bucket)}
    @type metrics :: %{optional(metric_key) => metric_value}
    @type t :: %__MODULE__{:metrics => metrics}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    LmAgent.TelemetryReporter.subscribe()

    schedule_push()

    {:ok, %State{}}
  end

  # We ignore _node as it's gonna always be localhost anyway
  @impl true
  def handle_info({:telemetry, name, ts, value, tags}, state) do
    state = update_in(
      state,
      Enum.map([:metrics, name, tags], &Access.key(&1, %{})),
      fn existing ->
        LmCommon.TelemetryData.add_telemetry_value(existing, value, ts)
      end)

    {:noreply, state}
  end

  def handle_info(:push, state) do
    schedule_push()

    if map_size(state.metrics) > 0 do
      LmAgent.BackendStorage.Client.send_telemetry(DateTime.utc_now(), state.metrics)
    end

    {:noreply, %State{state | metrics: %{}}}
  end

  defp schedule_push() do
    Process.send_after(self(), :push, LmAgent.send_telemetry_interval_ms())
  end
end
