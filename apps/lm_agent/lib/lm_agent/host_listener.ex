defmodule LmAgent.HostListener do
  use GenServer
  use TypedStruct

  require Logger

  @type telemetry_data :: %{
    count: integer(),
    avg: float(),
    min: float(),
    max: float(),
    last: float()
  }
  @type telemetry_bucket :: %{optional(DateTime.t()) => telemetry_data}

  @type tag_key :: map()

  @type metric_key :: list(atom())
  @type metric_value :: %{optional(tag_key) => list(telemetry_bucket)}

  @type metrics :: %{optional(metric_key) => metric_value}

  typedstruct module: State do
    field :metrics, LmAgent.HostListener.metrics(), default: %{}
  end

  def start_link(args, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl true
  def init(_args) do
    LmAgent.TelemetryReporter.subscribe()

    {:ok, %State{}}
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def get_metric(metric) when is_binary(metric) do
    metric
    |> String.split(".")
    |> Enum.map(&String.to_existing_atom/1)
    |> get_metric()
  end

  def get_metric(metric) when is_list(metric) do
    GenServer.call(__MODULE__, {:get_metric, metric})
  end

  @bucket_size 10

  @impl true
  def handle_info({:telemetry, name, ts, value, tags, node}, state) when not is_nil(value) do
    tags = Map.put(tags, :node, node)

    now = DateTime.to_unix(ts)

    current_bucket = DateTime.from_unix!(floor(now / @bucket_size) * @bucket_size)

    state = update_in(
      state,
      Enum.map([:metrics, name, tags, current_bucket], &Access.key(&1, %{})),
      fn
        data when map_size(data) == 0 ->
          %{
            count: 1,
            min: value,
            max: value,
            avg: value,
            last: value
          }
        data ->
          %{
            count: data.count + 1,
            min: min(value, data.min),
            max: max(value, data.max),
            avg: ((data.avg * data.count) + value) / (data.count + 1),
            last: value
          }
      end)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_metric, metric}, _from, state) do
    {:reply, Map.get(state.metrics, metric, %{}), state}
  end
end
