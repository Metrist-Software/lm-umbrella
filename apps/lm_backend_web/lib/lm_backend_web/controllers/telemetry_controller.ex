defmodule LmBackendWeb.Controllers.TelemetryController do
  use LmBackendWeb, :controller
  require Logger

  # one call per 29 seconds. Agent call in every 30 seconds,
  # we allow an extra second "fuzz" so we don't overdo rate
  # limiting.
  @rate_limit 29

  alias LmBackend.Telemetry.TelemetryEntry

  def post(conn, params) do
    # TODO: Require Account api token instead of User token, then pull account_id from session

    account_id = params["account_id"]
    node_name = params["node_name"]
    entries = params["entries"]
    datetime = params["datetime"]

    allowed_account_ids = get_session(conn, :account_ids)

    Logger.info(
      "Processing #{datetime}/#{account_id}/#{node_name} with #{Enum.count(entries)} entries."
    )

    with :ok <- validate_account_id(account_id, allowed_account_ids),
         :ok <- validate_rate(account_id, node_name) do
      changesets =
        entries
        |> Enum.map(fn telem ->
          attrs = %{
            time: telem["data"]["timestamp"],
            account_id: account_id,
            metric: telem["metric"],
            last: telem["data"]["last"],
            avg: telem["data"]["avg"],
            min: telem["data"]["min"],
            max: telem["data"]["max"],
            count: telem["data"]["count"],
            tags: Map.put(telem["tags"], "node", node_name)
          }

          changeset = TelemetryEntry.changeset(%TelemetryEntry{}, attrs)
          # Not the ideal location, but it will do for now.
          Ecto.Changeset.apply_changes(changeset)
          |> then(fn entry ->
            # The AgentPrescence updater requires a :utc_datetime where as TelemetryEntry uses :utc_datetime_usec
            # so we have to truncate the time here
            %{entry | time: DateTime.truncate(entry.time, :second)}
          end)
          |> LmBackend.telemetry_received()
          changeset
        end)

      case LmBackend.Telemetry.insert_entries(changesets) do
        :ok ->
          send_resp(conn, 201, ~s({"status": "ok"}))

        {:error, :duplicate_entry} ->
          send_resp(conn, 400, ~s({"error": "Duplicate entry"}))

        err ->
          Logger.error("Unknown error processing telemetry: #{inspect(err)}")
          send_resp(conn, 400, ~s({"error": "Unknown issue"}))
      end
    else
      {:error, :rate_limit} ->
        send_resp(conn, 429, ~s({"error": "Sending too fast"}))

      {:error, :forbidden} ->
        send_resp(conn, 403, ~s({"error": "Forbidden"}))
    end
  end

  defp validate_account_id(account_id, allowed_account_ids) do
    if account_id in allowed_account_ids do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp validate_rate(account_id, node_name) do
    # These reads-by-index should be cheap so for now we don't cache this.
    case LmBackend.Accounts.AgentPresence.last_seen(account_id, node_name) do
      nil ->
        :ok

      last_seen ->
        expect_no_later_than = DateTime.add(DateTime.utc_now(), -@rate_limit, :second)

        if DateTime.compare(last_seen, expect_no_later_than) == :gt do
          {:error, :rate_limit}
        else
          :ok
        end
    end
  end
end
