defmodule LmBackend.Telemetry do
  import Ecto.Query
  alias LmBackend.TelemetryRepo
  alias LmBackend.Telemetry.TelemetryEntry

  def get_data(metric, account_id, cutoff_minutes \\ 1440) do
    cutoff = DateTime.utc_now()
    |> DateTime.add(-cutoff_minutes, :minute)

    query = from t in TelemetryEntry,
      where: t.time > type(^cutoff, :utc_datetime_usec) and t.account_id == ^account_id and t.metric == ^metric

    TelemetryRepo.all(query)
  end

  def insert_entries(entries) do
    try do
      TelemetryRepo.insert_all(TelemetryEntry, Enum.map(entries, & &1.changes))
      :ok
    rescue
      err ->
        handle_insert_error(err)
    end
  end

  defp handle_insert_error(%Ecto.InvalidChangesetError{changeset: %{errors: errors}}) do
    if Keyword.has_key?(errors, :unique_time_account_id_metric) do
      {:error, :duplicate_entry}
    else
      {:error, :unknown}
    end
  end
  defp handle_insert_error(_), do: {:error, :unknown}
end
