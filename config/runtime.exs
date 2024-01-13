import Config

if System.get_env("PHX_SERVER") do
  config :lm_backend_web, LmBackendWeb.Endpoint, server: true
end

if config_env() == :prod do
  Application.ensure_all_started(:hackney)
  Application.ensure_all_started(:ex_aws_secretsmanager)

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :lm_backend_web, LmBackendWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  database_url = System.get_env("DATABASE_URL")

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :lm_backend, LmBackend.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  timescaledb_config = LmBackend.Secrets.get_secret("timescaledb/tokens")

  config :lm_backend, LmBackend.TelemetryRepo,
    username: timescaledb_config["username"],
    password: timescaledb_config["password"],
    database: timescaledb_config["database"],
    hostname: timescaledb_config["writeHost"],
    port: timescaledb_config["port"],
    ssl: true,
    pool_size: String.to_integer(timescaledb_config["pool_size"])
end
