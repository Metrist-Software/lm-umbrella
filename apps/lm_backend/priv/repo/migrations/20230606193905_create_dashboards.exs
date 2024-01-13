defmodule LmBackend.Repo.Migrations.CreateDashboards do
  use Ecto.Migration

  def change do
    create table(:dashboards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :panels, :map

      timestamps()
    end
  end
end
