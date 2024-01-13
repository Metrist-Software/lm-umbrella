import Config

if config_env() == :prod do
  secret_key_base =
    with nil <- System.get_env("SECRET_KEY_BASE") do
      length = 64

      :crypto.strong_rand_bytes(length)
      |> Base.encode64(padding: false)
      |> binary_part(0, length)
    end

  config :lm_agent_web, LmAgentWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  config :lm_agent,
    api_key: System.get_env("LM_API_KEY"),
    account_id: System.get_env("LM_ACCOUNT_ID"),
    backend_url: System.get_env("LM_BACKEND_URL", "https://metrics.metri.st"),
    data_dir: LmAgent.Env.data_dir(),
    send_telemetry_interval_ms: :timer.minutes(10),
    prometheus_metric_endpoint:
      System.get_env("LM_PROMETHEUS_METRIC_ENDPOINT", nil)

  ws_uri =
    System.get_env("LM_BACKEND_URL", "https://metrics.metri.st")
    |> URI.parse()
    |> Map.put(:scheme, "wss")
    |> Map.put(:path, "/datastream/websocket")

  config :lm_agent, LmAgent.DataStreamSocketClient,
    enabled: System.get_env("LM_DATASTREAM_ENABLED", "false") == "true",
    socket_opts: [
      uri: ws_uri,
      reconnect_after_msec: [200, 500, 1_000, 2_000]
    ]

  config :lm_agent, LmAgent.Statsd.Server,
    enabled: System.get_env("LM_STATSD_ENABLED", "false") == "true",
    flush_interval: String.to_integer(System.get_env("LM_STATSD_FLUSH_INTERVAL", "10")),
    port: String.to_integer(System.get_env("LM_STATSD_PORT", "8125")),
    dictionary_max_unique_dimensions: String.to_integer(System.get_env("LM_STATSD_DICTIONARY_MAX_UNIQUE_DIMENSIONS", "200"))
end
