# Adapted from https://medium.com/@joshnuss/meet-blip-a-statsd-server-in-elixir-48949fb819eb
defmodule LmAgent.Statsd.Parser do

  import NimbleParsec

  @parse_types ["c", "ms", "m", "g", "h", "s", "d"]
  @type_atoms %{
    "c"  => :counter,
    "ms" => :timer,
    "m"  => :meter,
    "g"  => :gauge,
    "h"  => :histogram,
    "s"  => :set,
    "d"  => :dictionary
  }

  number = ascii_string([?0..?9] ++ [?.], min: 1)
  acceptable_metric_chars = [?a..?z] ++ [?0..?9] ++ [?-, ?_, ?.]
  acceptable_value_chars = [not: ?|]
  metric = ascii_string(acceptable_metric_chars, min: 1)
  value = ascii_string(acceptable_value_chars, min: 1)

  type = @parse_types
  |> Enum.map(&string/1)
  |> choice

  value_part = ignore(string(":")) |> concat(value |> tag(:value))
  # binary_part = ignore(string(":")) |> concat(ascii_string(acceptable_chars, min: 1) |> tag(:binary123))
  type_part = ignore(string("|")) |> concat(type |> tag(:type))
  sampling_rate_part = ignore(string("|@")) |> concat(number |> tag(:sampling_rate))
  tags_part = ignore(string("|#")) |> concat(ascii_string([], min: 1) |> tag(:tags))

  line =
    metric |> tag(:metric)
    |> optional(value_part)
    |> optional(type_part)
    |> optional(sampling_rate_part)
    |> optional(tags_part)

  defparsec(
    :parse_line,
    line
  )

  def parse(input) do
    input
    |> String.trim()
    |> parse_line()
    |> format()
  end

  def format({:ok, acc, "" = _rest, %{} = _context, _line, _offset}),
    do: format(acc)

  def format([]) do
    {:ignore, "Ignoring blank"}
  end

  def format(acc) when is_list(acc) do
    line =
      acc
      |> Enum.reduce(%LmAgent.Statsd.Metric.StatsdEntry{}, fn item, acc ->
        case item do
          {:metric, [metric]} ->
            %{acc | metric: metric}

          {:value, [value]} ->
            %{acc | value: String.trim(value)}

          {:sampling_rate, [rate]} ->
            {value, _} =
              Float.parse(rate)

            value =
              value
              |> min(1.0)
              |> max(0.01)

            %{acc | sampling_rate: value}

          {:tags, [tags]} ->
            %{acc | tags: String.split(tags, ",")}

          {:type, [type]} ->
            %{acc | type: @type_atoms[type]}
        end
      end)

    {:ok, line}
  end

  def format({:ok, _acc, line, %{} = _context, _line, _offset}) do
    IO.inspect binding()
    {:ignore, "Unsupported syntax: #{inspect(line)}"}
  end

  def format({:error, message}),
    do: {:ignore, "Error parsing line #{message}"}
end
