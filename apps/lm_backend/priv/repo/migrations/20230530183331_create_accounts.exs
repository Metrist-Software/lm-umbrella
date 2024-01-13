defmodule LmBackend.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    # Lots of changes in a single migration as this is a 1:1 copy from MDS

    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps()
    end

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :provider, :string
      add :token, :string
      add :primary_account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    alter table(:accounts) do
      add :owner_id, references(:users, on_delete: :nothing, type: :binary_id)
    end

    create table(:users_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)
      timestamps()
    end

    create index(:users, [:email])
    create index(:users_accounts, [:user_id, :account_id], unique: true)
    create index(:users_accounts, [:account_id, :user_id], unique: true)

  end
end
