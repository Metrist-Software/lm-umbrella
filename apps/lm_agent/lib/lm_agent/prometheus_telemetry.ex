defmodule LmAgent.PrometheusTelemetry do
  require Logger
  alias PrometheusParser.Line
  defmodule Metric do
    defstruct type: nil,
              description: nil,
              lines: []
  end

  def dispatch_prometheus_metrics() do
    response =
      :get
      |> Finch.build(LmAgent.prometheus_metric_endpoint)
      |> Finch.request(Lm.Finch)

    case response do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {_, result} =
          body
          |> String.trim()
          |> String.split("\n")
          |> Enum.flat_map(fn line ->
             case PrometheusParser.parse(line) do
              {:ok, parsed} -> [parsed]
              _ -> []
             end
          end)
          |> Enum.reduce({nil, %{}}, &reducer/2)

        result
        |> Enum.flat_map(fn {_key, m} -> m.lines end)
        |> send_telemetry()

      {:ok, %Finch.Response{status: status}} ->
        Logger.error("get prometheus metrics responded with non 200 status, got: #{status}")

      {:error, err} ->
        Logger.error("get prometheus metrics failed. reason: #{inspect(err)}")
    end
  end

  defp send_telemetry(lines) do
    # Get rid of NaN values
    lines
    |> Enum.filter(fn line -> Float.parse(line.value) != :error end)
    |> Enum.map(fn entry ->
      {float, _rest} = Float.parse(entry.value)
      %{entry | value: float}
    end)
    |> Enum.map(fn line ->
      :telemetry.execute(
        [:lm, :prometheus_proxy],
        Map.take(line, [:value]),
        Map.merge(%{"metric_name" => line.label}, Map.new(line.pairs))
      )
    end)
  end

  defp reducer(line=%Line{line_type: "HELP"}, {_name, acc}) do
    acc = Map.update(acc, line.label, %Metric{description: line.documentation}, fn metric ->
      %{metric | description: line.documentation}
    end)
    {line.label, acc}
  end

  defp reducer(line=%Line{line_type: "TYPE", label: name}, {name, acc}) do
    acc = Map.update(acc, name, %Metric{type: line.type}, fn metric ->
      %{metric | type: line.type}
    end)
    {name, acc}
  end

  defp reducer(line = %Line{line_type: "ENTRY"}, {name, acc}) do
      acc = Map.update(acc, name, %Metric{lines: [line]}, fn metric ->
        %{metric | lines: [line | metric.lines]}
      end)
      {name, acc}
    end
end
