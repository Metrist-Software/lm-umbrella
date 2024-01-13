defmodule LmWeb.DashboardLive do
  use LmWeb, :live_view
  # alias VegaLite, as: Vl

  require Logger

  @config %{
    panels: [
      %{
        type: :line,
        metric: "vm.total_run_queue_lengths.cpu",
        # height: 2,
        width: 6
      },
      %{
        type: :line,
        metric: "vm.total_run_queue_lengths.io",
        # height: 2,
        width: 5
      },
      %{
        type: :line,
        metric: "vm.memory.total",
        # height: 2,
        width: 8
      }
    ]
  }

  def mount(_params, _session, socket) do
    socket = stream(socket, :data, [])

    # specs = @config.panels
    # |> Enum.map(fn panel ->
    #   panel.metric
    #   |> LmAgent.HostListener.get_metric()
    #   |> then(& {panel.metric, &1})
    #   |> LmWeb.Charts.line_chart()
    # end)
    # |> Map.new()
    specs = %{}

    socket = assign(socket, config: @config, specs: specs, ready: false)

    {:ok, socket}
  end

  def handle_event("element_resized", data, socket) do

    [metric_name | _] = String.split(data["id"], "-")

    spec = Map.get(socket.assigns.specs, metric_name)

    spec = spec
    |> Map.put("height", data["height"])
    |> Map.put("width", data["width"])

    specs = Map.put(socket.assigns.specs, metric_name, spec)

    {:noreply, assign(socket, specs: specs, ready: true)}
  end

  # defp metric_friendly_name(metric) when is_list(metric) do
  #   Enum.join(metric, ".")
  # end

  # defp metric_internal_name(metric) when is_binary(metric) do
  #   metric
  #   |> String.split(".")
  #   |> Enum.map(&String.to_existing_atom/1)
  # end
end
