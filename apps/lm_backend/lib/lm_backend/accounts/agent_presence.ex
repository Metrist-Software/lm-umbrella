defmodule LmBackend.Accounts.AgentPresence do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "agent_presence" do
    belongs_to(:account, LmBackend.Accounts.Account)
    field(:node_name, :string)
    field(:first_seen, :utc_datetime)
    field(:last_seen, :utc_datetime)
  end

  def seen(account_id, node_name, timestamp) do
    presence = %__MODULE__{
      account_id: account_id,
      node_name: node_name,
      first_seen: timestamp,
      last_seen: timestamp
    }

    LmBackend.Repo.insert(
      presence,
      conflict_target: [:account_id, :node_name],
      on_conflict: {:replace, [:last_seen]}
    )
    LmBackend.PubSub.agent_presence(presence)
  end

  def seen_all(entries) do
    LmBackend.Repo.transaction(fn ->
      Enum.each(entries, fn {a, n, t} -> seen(a, n, t) end)
    end)
  end

  def list(account_id) do
    query = from(p in __MODULE__,
      where: p.account_id == ^account_id)

    LmBackend.Repo.all(query)
  end

  def last_seen(account_id, node_name) do
    query =
      from(p in __MODULE__,
        where:
          p.account_id == ^account_id and
            p.node_name == ^node_name,
          select: p.last_seen
      )

    LmBackend.Repo.one(query)
  end
end
