defmodule LmBackend.Secrets do
  @moduledoc """
  Simple wrapper around secrets manager
  """
  require Logger

  def get_secret(path) do
    env = System.get_env("MDS_ENV", "localdev")
    region = System.get_env("MDS_REGION", "us-east-2")
    path = "mds/#{env}/lm-backend/#{path}"

    result =
      path
      |> ExAws.SecretsManager.get_secret_value()
      |> ExAws.request(region: region)

    case result do
      {:ok, %{"SecretString" => secret}} ->
        Logger.info("Successfully fetched secret '#{path}'")
        Jason.decode!(secret)

      {:error, error} ->
        raise "Error getting secret '#{path}': #{inspect(error)}"
        nil
    end
  end

  def create_secret(path, value) when is_map(value) do
    env = System.get_env("MDS_ENV", "localdev")
    region = System.get_env("MDS_REGION", "us-east-2")
    path = "mds/#{env}/lm-backend/#{path}"

    ExAws.SecretsManager.create_secret(
      client_request_token: Ecto.UUID.generate(),
      name: path,
      secret_string: Jason.encode!(value)
    )
    |> ExAws.request(region: region)
  end
end
