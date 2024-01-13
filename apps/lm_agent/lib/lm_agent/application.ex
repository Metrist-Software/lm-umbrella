defmodule LmAgent.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    LmCommon.set_umbrella_app_logger_metadata(__MODULE__)

    configure()

    children = [
      LmAgent.HostListener,
      LmAgent.LocalStorage.TelemetryWriter,
      LmAgent.DataStreamSocketClient,
      LmAgent.Statsd.Supervisor
    ]
    |> telemetry_sender_child_spec(LmAgent.enable_send_telemetry_to_backend())

    opts = [strategy: :one_for_one, name: LocalMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure() do
    configure_data_dir()
  end

  defp configure_data_dir() do
    LmAgent.LocalStorage.initialize()
  end

  def telemetry_sender_child_spec(children, true), do: children ++ [LmAgent.BackendStorage.TelemetrySender]
  def telemetry_sender_child_spec(children, false), do: children
end
