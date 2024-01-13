defmodule LmAgent.Statsd.Telemetry do
  @doc """
  This module broadcast any statsd metrics flushed on the flush interval for interested parties
  """

  @topic "#{__MODULE__}.telemetry"

  def subscribe() do
    unsubscribe()
    Phoenix.PubSub.subscribe(LmCommon.PubSub, @topic)
  end

  def unsubscribe() do
    Phoenix.PubSub.unsubscribe(LmCommon.PubSub, @topic)
  end

  def publish_metric(name, value, tags) do
    ts = DateTime.utc_now()
    Phoenix.PubSub.broadcast!(
      LmCommon.PubSub,
      @topic,
      {:statsd_telemetry, name, ts, value, tags}
    )
  end
end
