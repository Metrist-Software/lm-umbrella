defmodule LmAgentWeb.DashboardLive.FormComponent do
  use LmAgentWeb, :live_component

  alias LmAgent.Dashboards

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        id="dashboard-form"
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <fieldset>
          <legend>Panels</legend>
          <.inputs_for :let={f_panel} field={@form[:panels]}>
            <.panel f_panel={f_panel} myself={@myself} />
          </.inputs_for>
          <.button class="mt-2" type="button" phx-click="add_panel" phx-target={@myself}>Add</.button>
        </fieldset>

        <:actions>
          <.button phx-disable-with="Saving...">Save Dashboard</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def panel(assigns) do
    assigns = assign(assigns, :deleted, Phoenix.HTML.Form.input_value(assigns.f_panel, :delete) == true)
    ~H"""
    <div class={if @deleted, do: "opacity-50"}>
      <input
        type="hidden"
        name={Phoenix.HTML.Form.input_name(@f_panel, :delete)}
        value={to_string(Phoenix.HTML.Form.input_value(@f_panel, :delete))}
      />
      <div class="flex gap-4 items-end">
        <div class="grow">
          <.input field={@f_panel[:metric]} label="Metric" type="text" disabled={@deleted} required/>
        </div>
        <.input field={@f_panel[:type]} label="Type" type="select" options={["line", "bar", "bignumber", "pie"]} disabled={@deleted} required/>
        <.input field={@f_panel[:width]} label="Width" type="number" min="1" max="12" disabled={@deleted} required/>
        <.button class="grow-0" type="button" phx-click="delete_panel" phx-target={@myself} phx-value-index={@f_panel.index} disabled={@deleted}>
          Delete
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{dashboard: dashboard} = assigns, socket) do
    changeset = Dashboards.change_dashboard(dashboard)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp get_change_or_field(changeset, field) do
    with nil <- Ecto.Changeset.get_change(changeset, field) do
      Ecto.Changeset.get_field(changeset, field, [])
    end
  end

  @impl true
  def handle_event("add_panel", _, socket) do
    socket = update(socket, :form, fn %{source: changeset} ->
      existing = get_change_or_field(changeset, :panels)
      changeset = Ecto.Changeset.put_embed(changeset, :panels, existing ++ [%{}])
      to_form(changeset)
    end)

    {:noreply, socket}
  end

  def handle_event("delete_panel", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket = update(socket, :form, fn %{source: changeset} ->
      existing = get_change_or_field(changeset, :panels)
      {to_delete, rest} = List.pop_at(existing, index)
      panels = if Ecto.Changeset.change(to_delete).data.id do
        List.replace_at(existing, index, Ecto.Changeset.change(to_delete, delete: true))
      else
        rest
      end

      changeset
      |> Ecto.Changeset.put_embed(:panels, panels)
      |> to_form()
    end)

    {:noreply, socket}
  end

  def handle_event("validate", %{"dashboard" => params}, socket) do
    changeset = socket.assigns.dashboard
    |> LmCommon.Dashboards.Dashboard.changeset(params)
    |> struct!(action: :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"dashboard" => dashboard_params}, socket) do
    save_dashboard(socket, dashboard_params)
  end

  defp save_dashboard(socket, dashboard_params) do
    case Dashboards.update_dashboard(socket.assigns.dashboard, dashboard_params) do
      {:ok, dashboard} ->
        notify_parent({:saved, dashboard})

        {:noreply,
         socket
         |> put_flash(:info, "Dashboard updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
