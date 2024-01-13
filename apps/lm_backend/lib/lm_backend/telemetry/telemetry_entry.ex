defmodule LmBackend.Telemetry.TelemetryEntry do
  use Ecto.Schema
  @primary_key false
  import Ecto.Changeset

  schema "lm_telemetry" do
    field :time, :utc_datetime_usec

    field :account_id, :binary_id
    field :metric, :string

    field :last, :float
    field :avg, :float
    field :min, :float
    field :max, :float
    field :count, :integer

    field :tags, :map
  end

  @doc false
  def changeset(telemetry_entry, attrs) do
    telemetry_entry
    |> cast(attrs, [:time, :account_id, :metric, :last, :avg, :min, :max, :count, :tags])
    |> validate_required([:time, :account_id, :metric, :last, :avg, :min, :max, :count, :tags])
    |> unique_constraint(:unique_time_account_id_metric, name: :lm_telemetry_time_account_id_metric_unique_index)
  end
end
