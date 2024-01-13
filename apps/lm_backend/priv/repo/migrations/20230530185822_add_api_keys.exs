defmodule LmBackend.Repo.Migrations.AddApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:key, :string)
      add(:scope, :string)
      add(:scope_id, :string)

      timestamps()
    end

    create(index(:api_keys, [:key]))
    create(index(:api_keys, [:scope, :scope_id]))
  end
end
