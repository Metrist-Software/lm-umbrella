defmodule LmWeb.LogsLive do
  use LmWeb, :live_view

  require Logger

  @log_file_path "/var/log/syslog"
  @buffer_lines 20

  # Definitely not a great approach - don't want to actually load the entire file
  # into memory and serve 1 line at a time. Likely want to just stream larger
  # chunks to the frontend and let javascript handle things. But it works for now
  # as an initial PoC

  def mount(_params, _session, socket) do
    buffer = if connected?(socket) do
      lines = File.stream!(@log_file_path)
      |> Enum.to_list()

      {lines, lines_after} = Enum.split(lines, @buffer_lines)

      %{lines_before: [], lines: lines, lines_after: lines_after}
    else
      %{line: 0, lines: []}
    end

    {:ok, assign(socket, buffer: buffer)}
  end

  def handle_event("load_prev", _, socket) do
    %{lines_before: lines_before, lines: lines, lines_after: lines_after} = socket.assigns.buffer

    buffer = case lines_before do
      [] ->
        socket.assigns.buffer
      lines_before ->
        {added, lines_before} = List.pop_at(lines_before, -1)
        {removed, lines} = List.pop_at(lines, -1)

        lines = [added | lines]
        lines_after = [removed | lines_after]


        %{lines_before: lines_before, lines: lines, lines_after: lines_after}
    end

    {:noreply, assign(socket, buffer: buffer)}
  end

  def handle_event("load_next", _, socket) do
    %{lines_before: lines_before, lines: lines, lines_after: lines_after} = socket.assigns.buffer

    buffer = case lines_after do
      [] ->
        socket.assigns.buffer
      lines_after ->
        [removed | lines] = lines
        [added | lines_after] = lines_after

        lines_before = lines_before ++ [removed]
        lines = lines ++ [added]

        %{lines_before: lines_before, lines: lines, lines_after: lines_after}
    end

    {:noreply, assign(socket, buffer: buffer)}
  end

  def handle_info(_info, socket) do
    {:noreply, socket}
  end







end
