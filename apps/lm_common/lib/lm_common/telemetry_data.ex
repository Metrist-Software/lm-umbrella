defmodule LmCommon.TelemetryData do
  use TypedStruct

  @derive Jason.Encoder
  typedstruct do
    field :count, integer(), default: 0
    field :avg, float(), default: 0
    field :min, float(), default: 0
    field :max, float(), default: 0
    field :last, float() | nil, default: nil
    field :timestamp, DateTime.t()
  end

  def add_telemetry_value(%__MODULE__{last: last}=existing, value, ts) when not is_nil(last) do
    %__MODULE__{
      count: existing.count + 1,
      min: min(value, existing.min),
      max: max(value, existing.max),
      avg: ((existing.avg * existing.count) + value) / (existing.count + 1),
      last: value,
      timestamp: ts
    }
  end

  def add_telemetry_value(_, value, ts) do
    %__MODULE__{
      count: 1,
      min: value,
      max: value,
      avg: value,
      last: value,
      timestamp: ts
    }
  end
end
