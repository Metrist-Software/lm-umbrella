defmodule LmAgent.Dashboards do
  alias LmCommon.Dashboards.{Dashboard, Panel}

  def get() do
    case LmAgent.LocalStorage.open_for_read(LmAgent.data_dir(), ["dashboard"], 0) do
      nil ->
        default_dashboard()
      file ->
        dashboard = case LmAgent.LocalStorage.File.read_bin(file) do
          nil ->
            default_dashboard()
          bytes ->
            :erlang.binary_to_term(bytes)
        end
        LmAgent.LocalStorage.close(file)
        dashboard
    end
  end

  def update_dashboard(%Dashboard{} = dashboard, attrs) do
    changeset = dashboard
    |> Dashboard.changeset(attrs)

    case changeset do
      %{valid?: false} -> {:error, changeset}
      _ ->
        dashboard = changeset
        |> Ecto.Changeset.apply_changes()
        |> ensure_panel_ids()
        |> timestamps()

        file = LmAgent.LocalStorage.open_for_write(LmAgent.data_dir(), ["dashboard"], 0, append: false)
        binary = :erlang.term_to_binary(dashboard)
        LmAgent.LocalStorage.File.write_bin(file, binary)
        LmAgent.LocalStorage.close(file)

        {:ok, dashboard}
    end
  end

  defp ensure_panel_ids(dashboard) do
    dashboard.panels
    |> Enum.map(fn panel ->
      case panel.id do
        nil -> %{panel | id: Ecto.UUID.generate()}
        _ -> panel
      end
    end)
    |> then(& %{dashboard | panels: &1})
  end

  defp timestamps(dashboard) do
    %{dashboard | updated_at: DateTime.utc_now()}
  end

  def change_dashboard(%Dashboard{} = dashboard, attrs \\ %{}) do
    Dashboard.changeset(dashboard, attrs)
  end

  defp default_dashboard() do
    %Dashboard{
      id: "dashboard",
      account_id: "local",
      panels: [
        %Panel{id: Ecto.UUID.generate(), type: "line", metric: "vm.memory.total", width: 12}
      ],
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end
end
