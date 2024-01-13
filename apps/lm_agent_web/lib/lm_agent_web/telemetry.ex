defmodule LmAgentWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      {LmAgent.TelemetryReporterSupervisor, metrics: metrics()}
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
      summary("lm_agent_web.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("lm_agent_web.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("lm_agent_web.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("lm_agent_web.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("lm_agent_web.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Our own
      summary("lm_agent.os.disk_usage.capacity_kb", unit: :kilobyte, tags: [:path]),
      summary("lm_agent.os.disk_usage.free_kb", unit: :kilobyte, tags: [:path]),
      summary("lm_agent.os.disk_usage.used_kb", unit: :kilobyte, tags: [:path]),

      summary("lm_agent.os.mem_usage.available_memory", unit: :byte),
      summary("lm_agent.os.mem_usage.total_memory", unit: :byte),

      last_value("lm.prometheus_proxy.value")
    ]
  end

  defp periodic_measurements do
    [
      {LmAgent.OsTelemetry, :dispatch_os_telem, []},
    ]
    |> prometheus_telemetry_mfa(LmAgent.enable_scrape_prometheus_metrics())
  end

  def prometheus_telemetry_mfa(other, true), do: other ++ [{LmAgent.PrometheusTelemetry, :dispatch_prometheus_metrics, []}]
  def prometheus_telemetry_mfa(other, false), do: other
end
