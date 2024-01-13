defmodule LmWeb.VegaLiteComponent do
  use LmWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, id: assigns.id)

    {:ok, push_event(socket, event_name(socket.assigns.id, "init"), %{spec: assigns.spec})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"vega-lite-#{@id}"}
      phx-hook="VegaLite"
      phx-update="ignore"
      data-id={@id}
      class="grow w-full -mb-2" />
    """
  end

  def event_name(id, event), do: "vega_lite:#{id}:#{event}"
end
