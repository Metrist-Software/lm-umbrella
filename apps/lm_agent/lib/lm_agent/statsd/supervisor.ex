defmodule LmAgent.Statsd.Supervisor do
  use Supervisor

  @registry :statsd_metric_registry

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, [keys: :unique, name: @registry]},
      LmAgent.Statsd.MetricsSupervisor,
      LmAgent.Statsd.Server
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
