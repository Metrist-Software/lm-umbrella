defmodule LmAgent.PrometheusMetricCache do
  def new_value?(key, value) do
    case Cachex.get(cache(), key) do
      {:ok, ^value} ->
        false

      {:ok, _} ->
        true
    end
  end

  def put(key, value) do
    Cachex.put(cache(), key, value)
  end

  def cache(), do: :prometheus_reporter_cache
end
