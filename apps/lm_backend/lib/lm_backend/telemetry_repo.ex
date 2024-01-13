defmodule LmBackend.TelemetryRepo do
  use Ecto.Repo,
    otp_app: :lm_backend,
    adapter: Ecto.Adapters.Postgres
end
