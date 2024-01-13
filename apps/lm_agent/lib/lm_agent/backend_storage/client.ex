defmodule LmAgent.BackendStorage.Client do
  require Logger

  def send_telemetry(dt, telemetry) do
    body =
      telemetry
      |> transform_telemetry(dt)
      |> tap(fn data -> Logger.info("Sending #{length(data.entries)} telemetries to backend") end)
      |> Jason.encode!()

    request("/api/telemetry", body, :post)
    |> handle_response()
  end

  def handle_response({:ok, %Finch.Response{status: status}}) do
    Logger.info("send telemetry to backend with status #{inspect(status)}")
  end

  def handle_response({:error, reason}) do
    Logger.error("send telemetry to backend failed with reason: #{inspect(reason)}")
  end

  defp transform_telemetry(telemetry, dt) do
    account_id = LmAgent.account_id()
    node_name = LmAgent.agent_id()

    entries =
      Enum.flat_map(telemetry, fn {metric_name, tagged_data} ->
        Enum.map(tagged_data, fn {tags, data} ->
          %{
            metric: Enum.join(metric_name, "."),
            tags: tags,
            data: data
          }
        end)
      end)

    %{account_id: account_id, node_name: node_name, datetime: dt, entries: entries}
  end

  def request(path, body, method \\ :get) do
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    Finch.build(
      method,
      "#{LmAgent.backend_url()}#{path}",
      [
        {"authorization", "Bearer #{LmAgent.api_key()}"},
        {"Content-Type", "application/json"}
      ],
      body
    )
    |> Finch.request(Lm.Finch)
  end
end
