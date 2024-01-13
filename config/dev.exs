import Config

root_path =
  __ENV__.file
  |> Path.dirname()
  |> Path.join("..")
  |> Path.expand()
  |> Path.join("apps")

reloadable_apps = [:lm_web, :lm_common, :lm_agent, :lm_backend, :lm_backend_web, :lm_agent_web]

dirs = Enum.map(reloadable_apps, &(Path.join([root_path, Atom.to_string(&1)])))

config :phoenix_live_reload, :dirs, dirs

config :lm_agent_web, LmAgentWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
    https: [
    ip: {127, 0, 0, 1},
    port: 8443,
    cipher_suite: :strong,
    keyfile: "priv/localhost+2-key.pem",
    certfile: "priv/localhost+2.pem"
  ],
  check_origin: false,
  code_reloader: true,
  # Compare with reloadable_apps above
  reloadable_apps: [:lm_web, :lm_common, :lm_agent, :lm_agent_web],
  debug_errors: true,
  secret_key_base: "A4xP1aT2CqD2ZDSOlcd/vvchg4hTmQNgwkSjJphBWuLFoTvqmD/0pZH2qf+4TqaM",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:lm_agent_web, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:lm_agent_web, ~w(--watch)]}
  ]

config :lm_agent_web, LmAgentWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/lm_agent_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"../lmb_web/priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"../lm_web/lib/lm_web/(controllers|live|components)/.*(ex|heex)$",
    ]
  ]

config :lm_agent_web, dev_routes: true

config :lm_agent,
  api_key: System.get_env("LM_API_KEY"),
  account_id: System.get_env("LM_ACCOUNT_ID"),
  backend_url: System.get_env("LM_BACKEND_URL", "https://localhost:4443")

ws_uri = System.get_env("LM_BACKEND_URL", "https://localhost:4443")
|> URI.parse()
|> Map.put(:scheme, "wss")
|> Map.put(:path, "/datastream/websocket")

config :lm_agent, LmAgent.DataStreamSocketClient,
  enabled: System.get_env("LM_DATASTREAM_ENABLED", "true") == "true",
  socket_opts: [
    uri: ws_uri,
    mint_opts: [
      protocols: [:http1],
      transport_opts: [
        verify: :verify_none
      ]
    ],
    reconnect_after_msec: [200, 500, 1_000, 2_000]
  ]

config :lm_agent, LmAgent.Statsd.Server,
  enabled: System.get_env("LM_STATSD_ENABLED", "false") == "true",
  flush_interval: String.to_integer(System.get_env("LM_STATSD_FLUSH_INTERVAL", "10")),
  port: String.to_integer(System.get_env("LM_STATSD_PORT", "8125")),
  dictionary_max_unique_dimensions: String.to_integer(System.get_env("LM_STATSD_DICTIONARY_MAX_UNIQUE_DIMENSIONS", "200"))

config :lm_backend_web, LmBackendWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  https: [
    ip: {127, 0, 0, 1},
    port: 4443,
    cipher_suite: :strong,
    keyfile: "priv/localhost+2-key.pem",
    certfile: "priv/localhost+2.pem"
  ],
  check_origin: false,
  code_reloader: true,
  # Compare with reloadable_apps above
  reloadable_apps: [:lm_web, :lm_common, :lm_backend, :lm_backend_web],
  debug_errors: true,
  secret_key_base: "SRT0lnRp7pSudtMwEcvo63TPMH3mS/SeO3Sj8SmtR+HkDyY6HXIPAtyPBCcfucIH",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:lm_backend_web, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:lm_backend_web, ~w(--watch)]}
  ]

config :lm_backend_web, LmBackendWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/lm_backend_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"../lmb_web/priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"../lm_web/lib/lm_web/(controllers|live|components)/.*(ex|heex)$",
    ]
  ]

config :lm_backend_web, dev_routes: true

config :lm_backend, LmBackend.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "lm_backend_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :lm_backend, LmBackend.TelemetryRepo,
  username: "postgres",
  password: "postgres",
  database: "postgres",
  hostname: "localhost",
  port: 5532,
  pool_size: 10

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email", send_redirect_uri: false]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email", callback_port: 4443]}
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :logger, :console,
  format: "$time $metadata- [$level] $message\n",
  metadata: [:app],
  level: :debug
