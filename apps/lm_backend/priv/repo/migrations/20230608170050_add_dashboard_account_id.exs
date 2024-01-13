defmodule LmBackend.Repo.Migrations.AddDashboardAccountId do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      add :account_id, :binary_id
    end
  end
end
