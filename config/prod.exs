import Config

config :lm_backend_web, LmBackendWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :lm_agent_web, LmAgentWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
