defmodule LmBackend.TelemetryRepo.Migrations.AddUniqueIndex do
  use Ecto.Migration

  def change do
    drop index(:lm_telemetry, [:time, :account_id, :metric])
    create unique_index(:lm_telemetry, [:time, :account_id, :metric], name: :lm_telemetry_time_account_id_metric_unique_index)
  end
end
