defmodule LmWeb.IndexLive do
  use LmWeb, :live_view
  # alias VegaLite, as: Vl

  require Logger

  def mount(_params, _session, socket) do

    socket = stream(socket, :data, [])

    # LmAgent.TelemetryReporter.subscribe()

    # specs = LmAgent.HostListener.get_state()
    #   |> Map.get(:metrics)
    #   |> Enum.map(&LmWeb.Charts.line_chart/1)
    specs = []

    socket = assign(socket, specs: specs)

    Process.send_after(self(), :get_data, 1000)

    {:ok, socket}
  end

  def handle_info(:get_data, socket) do
    # specs = LmAgent.HostListener.get_state()
    # |> Map.get(:metrics)
    # |> Enum.map(&LmWeb.Charts.line_chart/1)
    specs = []

    socket = assign(socket, specs: specs)

    Process.send_after(self(), :get_data, 5_000)

    {:noreply, socket}
  end

  def handle_info(_info, socket) do
    {:noreply, socket}
  end
end
