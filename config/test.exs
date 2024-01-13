import Config

config :lm_backend_web, LmBackendWeb.Endpoint,
  server: false

config :lm_agent_web, LmAgentWeb.Endpoint,
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :lm_agent, LmAgent.DataStreamSocketClient,
  enabled: false

config :lm_agent, LmAgent.Statsd.Server,
  enabled: false
