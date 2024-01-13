defmodule LmWeb.Charts do
  alias VegaLite, as: Vl

  require Logger

  def transform_data(data) do
    transformed_data =
      data
      |> Enum.flat_map(fn {tags, buckets} ->
        Enum.map(buckets, fn {time, entry} ->
          format_datum(time, entry.avg, tags)
        end)
      end)

    transformed_data
  end

  def format_datum(time, value, tags) do
    %{time: time, value: value, tags: atomize_tags(tags)}
  end

  def atomize_tags(tags) do
    Enum.reduce(tags, "", fn {key, val}, acc ->
      case acc do
        "" -> "#{key}:#{val}"
        acc -> "#{acc}_#{key}:#{val}"
      end
    end)
    |> String.to_atom()
  end

  def chart_update_event(telemetry, %{type: type}) when type in ["line", "bar"] do
    {"add_telem", format_datum(telemetry.time, telemetry.avg, telemetry.tags)}
  end

  def chart_update_event(telemetry, %{type: "bignumber"}) do
    value = telemetry.avg
    |> Float.round()

    {"replace_telem", %{"a" => value}}
  end

  def chart_update_event(telemetry, %{type: "pie"}) do
    {"swap_telem", %{tags: atomize_tags(telemetry.tags), value: telemetry.avg}}
  end

  def chart(%LmCommon.Dashboards.Panel{type: "line"} = panel, tagged_metrics) do
    make_chart(panel, tagged_metrics, :line)
  end

  def chart(%LmCommon.Dashboards.Panel{type: "bar"} = panel, tagged_metrics) do
    make_chart(panel, tagged_metrics, :bar)
  end

  def chart(%LmCommon.Dashboards.Panel{type: "pie"} = panel, tagged_metrics) do
    data = transform_data(tagged_metrics)
    |> Enum.reduce(%{}, fn x, acc ->
      # For now, we just grab the most recent value for each tag. Tdb.
      Map.put(acc, x.tags, x.value)
    end)
    |> Enum.map(fn {k, v} -> %{tags: k, value: v} end)

    Vl.new(
      width: "container",
      height: "container",
      title: panel.metric,
      autosize: %{type: "fit", contains: "padding"}
    )
    |> Vl.data_from_values(data, name: "chart")
    |> Vl.mark(:arc, tooltip: true)
    |> Vl.encode_field(:theta, "value", type: :quantitative)
    |> Vl.encode_field(:color, "tags", type: :nominal)
    |> Vl.to_spec()

  end

  def chart(%LmCommon.Dashboards.Panel{type: "bignumber"} = panel, tagged_metrics) do
    # This is a temporary solution. At some point we probably want this not to
    # be in VegaLite.

    # Note that at some point we probably want to specify an operation and think
    # about tags, but for now we'll just grab the last value.
    data =
      tagged_metrics
      |> transform_data()
      |> List.last()

    data =
      case data do
        nil ->
          0

        _ ->
          data
          |> Map.get(:value)
          |> Float.round()
      end


    # We had the JSON from the VegaLite editor, nice juxtaposition to the
    # `Vl` library DSL.
    %{
    "$schema" => "https =>//vega.github.io/schema/vega-lite/v5.json",
    "autosize" => %{"contains" => "padding", "type" => "fit"},
    "height" => "container",
    "width" => "container",
    "data" => %{"values" => [%{"a" => data}], "name" => "chart"},
    "encoding" => %{"text" => %{"field" => "a", "type" => "quantitative"}},
    "mark" => %{
      "type" => "text",
      "fill" => "black",
      "fontSize" => 80,
      "fillOpacity" => 1,
      "align" => "center"
    },
    "title" => panel.metric,
    "config" => %{"view" => %{"stroke" => "transparent"}}
    }

  end

  defp make_chart(panel, tagged_metrics, kind) do
    data = transform_data(tagged_metrics)

    Vl.new(
      width: "container",
      height: "container",
      title: panel.metric,
      autosize: %{type: "fit", contains: "padding"}
    )
    |> Vl.data_from_values(data, name: "chart")
    |> Vl.encode_field(:x, "time", type: :temporal, title: "Time")
    |> Vl.encode_field(:y, "value", type: :quantitative, title: "Average value")
    |> Vl.encode_field(:color, "tags", type: :nominal, legend: [orient: :bottom, columns: 2])
    |> Vl.layers([
      Vl.new()
      |> Vl.mark(kind),
      Vl.new()
      |> Vl.mark(:circle, tooltip: true)
      |> Vl.encode(:opacity,
        value: 0,
        condition: [test: [param: "hover", empty: false], value: 1]
      )
      |> Vl.encode(:size,
        value: 100,
        condition: [test: [param: "hover", empty: false], value: 48]
      )
      |> Vl.param("hover",
        select: [type: "point", nearest: true, on: "mouseover", clear: "mouseout"]
      )
    ])
    |> Vl.to_spec()
  end
end
