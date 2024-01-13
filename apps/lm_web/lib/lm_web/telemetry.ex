defmodule LmWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: :timer.seconds(5)},
      # {:telemetry_poller, measurements: periodic_prometheus(), period: :timer.seconds(10), name: :prom_poller},
      {Lm.TelemetryReporter, metrics: metrics()},
      # {TelemetryMetricsStatsd, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      # summary("phoenix.channel_join.duration",
      #   unit: {:native, :millisecond}
      # ),
      # summary("phoenix.channel_handled_in.duration",
      #   tags: [:event],
      #   unit: {:native, :millisecond}
      # ),

      # Database Metrics
      summary("lm.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("lm.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("lm.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("lm.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("lm.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Custom
      summary("lm.os.disk_usage.percent_used", unit: :percent, tags: [:path]),
      summary("lm.os.disk_usage.capacity_kb", unit: :kilobyte, tags: [:path]),
      summary("lm.os.disk_usage.free_kb", unit: :kilobyte, tags: [:path]),
      summary("lm.os.disk_usage.used_kb", unit: :kilobyte, tags: [:path]),

      summary("lm.os.mem_usage.available_memory", unit: :byte),
      summary("lm.os.mem_usage.total_memory", unit: :byte)
    ]
  end

  defp periodic_measurements do
    [
      {Lm.OsTelemetry, :dispatch_os_telem, []}
    ]
  end
end
