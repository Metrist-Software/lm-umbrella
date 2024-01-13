# Adapted from https://medium.com/@joshnuss/meet-blip-a-statsd-server-in-elixir-48949fb819eb
defmodule LmAgent.Statsd.Server do
  @moduledoc """
  Statsd server built into the agent.

  You can enable the server by setting LM_STATSD_ENABLED to true. Defaults to disabled
  Port can be configured with LM_STATSD_PORT. Defaults to 8125
  Flush interval in seconds can be configured with LM_STATSD_FLUSH_INTERVAL. Defaults to 10
  """
  use GenServer, restart: :permanent

  alias LmAgent.Statsd.Parser

  require Logger

  defmodule State do
    defstruct flush_interval: 10,
              socket: nil
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    config = Application.fetch_env!(:lm_agent, __MODULE__)
    if config[:enabled] do
      port = config[:port]
      flush_interval = config[:flush_interval]
      Logger.debug("Statsd - Starting Statsd server on #{port} with flush interval #{flush_interval}s")
      schedule_flush(flush_interval)
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true])
      {:ok, %State{ flush_interval: flush_interval, socket: socket}}
    else
      :ignore
    end
  end

  def handle_info({:udp, _socket, _address, _port, data}, state) do
    case Parser.parse(data) do
      {:ok, entry} ->
        LmAgent.Statsd.MetricsSupervisor.process_metric(entry)
      {:ignore, _line} ->
        Logger.debug("Statsd - Ignoring: #{inspect data}")
    end

    {:noreply, state}
  end

  def handle_info(:flush, %State{ flush_interval: flush_interval } = state) do
    Logger.debug("Statsd - Server flushing")

    LmAgent.Statsd.MetricsSupervisor.flush()
    schedule_flush(flush_interval)
    {:noreply, state}
  end

  defp schedule_flush(flush_interval) do
    Process.send_after(self(), :flush, :timer.seconds(flush_interval))
  end
end
