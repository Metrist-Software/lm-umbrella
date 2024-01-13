defmodule LmCommon.Dashboards.Panel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :metric, :string
    field :width, :integer
    field :delete, :boolean, virtual: true
  end

  def changeset(panel, attrs) do
    changeset = panel
    |> cast(attrs, [:type, :metric, :width, :delete])
    |> validate_required([:type, :metric, :width])

    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
