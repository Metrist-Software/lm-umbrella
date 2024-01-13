defmodule LmBackend.Repo.Migrations.AddAgentPresence do
  use Ecto.Migration

  def change do
    create table(:agent_presence, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :node_name, :string
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :first_seen, :utc_datetime
      add :last_seen, :utc_datetime
    end
  end
end
