defmodule LmBackend.Dashboards do
  @moduledoc """
  The Dashboards context.
  """

  import Ecto.Query, warn: false
  alias LmBackend.Repo

  alias LmCommon.Dashboards.Dashboard

  def list_dashboards(account_id) do
    query =
      from d in Dashboard,
        where: d.account_id == ^account_id

    Repo.all(query)
  end

  def get_dashboard!(id), do: Repo.get!(Dashboard, id)

  def create_dashboard(attrs \\ %{}) do
    %Dashboard{}
    |> Dashboard.changeset(attrs)
    |> Repo.insert()
  end

  def update_dashboard(%Dashboard{} = dashboard, attrs) do
    dashboard
    |> Dashboard.changeset(attrs)
    |> Repo.update()
  end

  def delete_dashboard(%Dashboard{} = dashboard) do
    Repo.delete(dashboard)
  end

  def change_dashboard(%Dashboard{} = dashboard, attrs \\ %{}) do
    Dashboard.changeset(dashboard, attrs)
  end
end
