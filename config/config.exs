# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, :system, 30}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, {:awscli, :system, 30}, :instance_role]

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email", send_redir_uri: false]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email"]}
  ]

config :lm_backend_web,
  ecto_repos: [LmBackend.Repo, LmBackend.TelemetryRepo],
  generators: [context_app: :lm_backend]

# Configures the endpoint
config :lm_backend_web, LmBackendWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: LmBackendWeb.ErrorHTML, json: LmBackendWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LmCommon.PubSub,
  live_view: [signing_salt: "3irGJsJa"],
  server: true

config :lm_agent_web,
  generators: [context_app: :lm_agent]

# Configures the endpoint
config :lm_agent_web, LmAgentWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: LmAgentWeb.ErrorHTML, json: LmAgentWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LmCommon.PubSub,
  live_view: [signing_salt: "YKnwEsO6"],
  server: true

config :lm_backend,
  ecto_repos: [LmBackend.Repo, LmBackend.TelemetryRepo],
  generators: [context_app: false]

config :lm_agent,
  generators: [context_app: false],
  data_dir: "/tmp/lm_agent/",
  send_telemetry_interval_ms: :timer.seconds(30),
  prometheus_metric_endpoint: System.get_env("LM_PROMETHEUS_METRIC_ENDPOINT", nil)

# It's a Phoenix app, but just with common code.
config :lm_web, LMWeb.Endpoint, server: false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  lm_agent_web: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/lm_agent_web/assets", __DIR__),
    env: %{
      "NODE_PATH" =>
        Enum.join(
          [
            Path.expand("../deps", __DIR__),
            Path.expand("../apps/lm_web/assets/node_modules", __DIR__)
          ],
          ":"
        )
    }
  ],
  lm_backend_web: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/lm_backend_web/assets", __DIR__),
    env: %{
      "NODE_PATH" =>
        Enum.join(
          [
            Path.expand("../deps", __DIR__),
            Path.expand("../apps/lm_web/assets/node_modules", __DIR__)
          ],
          ":"
        )
    }
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  lm_agent_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/lm_agent_web/assets", __DIR__)
  ],
  lm_backend_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/lm_backend_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :libcluster,
  debug: true,
  topologies: [
    local_epmd: [
      strategy: Elixir.Cluster.Strategy.LocalEpmd
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
