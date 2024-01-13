defmodule LmAgent.Statsd.Metric do
  use TypedStruct

  @type metric_type :: :counter | :gauge | :timer | :meter | :histogram | :set | :dictionary

  @type_modules %{
    :counter => LmAgent.Statsd.MetricTypes.Counter,
    # Meter is an increment only counter
    :meter => LmAgent.Statsd.MetricTypes.Counter,
    :gauge  => LmAgent.Statsd.MetricTypes.Gauge,
    :timer => LmAgent.Statsd.MetricTypes.Timer,
    # Timer and histogram emit the same metrics
    :histogram => LmAgent.Statsd.MetricTypes.Timer,
    :set => LmAgent.Statsd.MetricTypes.Set,
    :dictionary => LmAgent.Statsd.MetricTypes.Dictionary
  }

  typedstruct module: StatsdEntry do
    field :metric, :binary
    field :value, :binary, default: nil
    field :sampling_rate, :float, default: 1.0
    field :tags, list(), default: []
    # If no type is sent, :counter is the default
    field :type, LmAgent.Statsd.Metric.metric_type, default: :counter
  end

  @callback init(%StatsdEntry{}) :: map()
  @callback flush(state :: map()) :: map()
  @callback process(%StatsdEntry{}, state :: map()) :: map()

  def find_metric_module_for_entry(%StatsdEntry{ type: type }), do: Map.get(@type_modules, type)
end
