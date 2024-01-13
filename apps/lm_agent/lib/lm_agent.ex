defmodule LmAgent do
  @doc """
  Returns the root directory for storing local metrics
  """
  def data_dir, do: Application.get_env(:lm_agent, :data_dir)
  def api_key, do: Application.get_env(:lm_agent, :api_key)
  def account_id, do: Application.get_env(:lm_agent, :account_id)
  def backend_url, do: Application.get_env(:lm_agent, :backend_url)

  def send_telemetry_interval_ms, do: Application.get_env(:lm_agent, :send_telemetry_interval_ms)
  def enable_send_telemetry_to_backend,
    do: Enum.all?([api_key(), account_id(), backend_url()], &(&1 != nil))

  def prometheus_metric_endpoint, do: Application.get_env(:lm_agent, :prometheus_metric_endpoint)
  def enable_scrape_prometheus_metrics, do: prometheus_metric_endpoint() != nil

  def agent_id do
    {:ok, host} = :net.gethostname()
    System.get_env("LM_AGENT_ID", List.to_string(host))
  end
end
