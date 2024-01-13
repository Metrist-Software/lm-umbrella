defmodule LmBackend.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    LmCommon.set_umbrella_app_logger_metadata(__MODULE__)

    configure()

    children =
      [
        LmBackend.Repo,
        LmBackend.TelemetryRepo,
        LmBackend.AgentPresenceUpdater,
      ] ++
        maybe_start_libcluster()

    opts = [strategy: :one_for_one, name: LmBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def maybe_start_libcluster() do
    case Application.get_env(:libcluster, :topologies) do
      nil ->
        Logger.info("Not starting libcluster, no topologies defined")
        []

      topologies ->
        Logger.info("Starting libcluster with #{inspect(topologies)}")
        [{Cluster.Supervisor, [topologies, [name: LmBackend.ClusterSupervisor]]}]
    end
  end

  defp configure() do
    # Configure some stuff that is really runtime but we also want to treat as runtime in dev.
    configure_oauth_github()
    configure_oauth_google()
  end

  defp configure_oauth_github() do
    # TODO this now appears twice, here and runtime.exs
    github_secret = LmBackend.Secrets.get_secret("oauth/github")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: Map.get(github_secret, "client_id"),
      client_secret: Map.get(github_secret, "client_secret")
    )
  end

  defp configure_oauth_google() do
    google_secret = LmBackend.Secrets.get_secret("oauth/google")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: Map.get(google_secret, "client_id"),
      client_secret: Map.get(google_secret, "client_secret")
    )
  end
end
