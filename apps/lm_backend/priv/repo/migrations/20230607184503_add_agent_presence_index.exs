defmodule LmBackend.Repo.Migrations.AddAgentPresenceIndex do
  use Ecto.Migration

  def change do
    create index(:agent_presence, [:account_id, :node_name], unique: true)
  end
end
