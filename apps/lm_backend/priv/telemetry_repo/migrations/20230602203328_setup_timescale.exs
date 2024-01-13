defmodule LmBackend.TelemetryRepo.Migrations.SetupTimescale do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS timescaledb;"

    create table(:lm_telemetry, primary_key: false) do
      add :time, :utc_datetime_usec
      add :account_id, :binary_id
      add :metric, :string
      add :last, :float
      add :min, :float
      add :max, :float
      add :avg, :float
      add :count, :integer
      add :tags, :map
    end

    create index(:lm_telemetry, [:time])
    create index(:lm_telemetry, [:time, :account_id, :metric])
    create index(:lm_telemetry, [:tags], using: "GIN")
  end
end
