defmodule LmAgentWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    LmCommon.set_umbrella_app_logger_metadata(__MODULE__)

    children = [
      # Start the Telemetry supervisor
      LmAgentWeb.Telemetry,
      # Start the Endpoint (http/https)
      LmAgentWeb.Endpoint
      # Start a worker by calling: LmAgentWeb.Worker.start_link(arg)
      # {LmAgentWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LmAgentWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LmAgentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
