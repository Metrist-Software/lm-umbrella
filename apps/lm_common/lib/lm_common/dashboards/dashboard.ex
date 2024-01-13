defmodule LmCommon.Dashboards.Dashboard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "dashboards" do
    belongs_to :account, LmBackend.Accounts.Account

    embeds_many :panels, LmCommon.Dashboards.Panel, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:account_id])
    |> cast_embed(:panels, with: &LmCommon.Dashboards.Panel.changeset/2)
    |> validate_required([:account_id])
  end
end
