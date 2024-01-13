defmodule LmAgent.LocalStorage.File do
  @moduledoc """
  """
  @magic "LMAF0000"

  @resolution :microsecond

  def open_for_write(dir, names, day, opts \\ []) when is_list(names) do
    dirname = dirname(dir, names)
    filename = filename(dirname, day)

    should_append = Keyword.get(opts, :append, true)

    if File.exists?(filename) and should_append do
      verify_file(filename)
      File.open!(filename, [:append, :binary])
    else
      file = File.open!(filename, [:write, :binary])
      IO.binwrite(file, @magic)
      file
    end
  end

  def open_for_read(dir, names, day) when is_list(names) do
    dirname = dirname(dir, names)
    filename = filename(dirname, day)
    if File.exists?(filename) do
      verify_file(filename, false)
    else
      nil
    end
  end

  def read(file) do
    case read_bin(file) do
      nil -> nil
      bytes ->
        {time, value, tags} = :erlang.binary_to_term(bytes)
        {:ok, time} = DateTime.from_unix(time, @resolution)
        {time, value, tags}
    end
  end

  def read_bin(file) do
    case IO.binread(file, 4) do
      :eof -> nil
      bytes ->
        <<size::unsigned-32-big>> = bytes
        IO.binread(file, size)
    end
  end

  def write(file, time, value, tags) do
    time = DateTime.to_unix(time, @resolution)
    binary = :erlang.term_to_binary({time, value, tags})

    write_bin(file, binary)
  end

  def write_bin(file, binary) do
    size = :erlang.size(binary)
    size_bytes = <<size::unsigned-32-big>>
    IO.binwrite(file, size_bytes)
    IO.binwrite(file, binary)
  end

  defp dirname(dir, names) do
    names = Enum.map(names, &"#{&1}")
    dirname = Path.join([dir | names])
    File.mkdir_p!(dirname)
    dirname
  end

  defp filename(dir, day) do
    Path.join(dir, "#{day}.dat")
  end

  defp verify_file(filename, do_close \\ true) do
    file = File.open!(filename, [:read, :binary, :read_ahead])
    magic = IO.binread(file, 8)
    if do_close, do: File.close(file)
    if magic != @magic do
      raise "Unknown/bad magic [#{inspect magic}] in #{filename}!"
    end
    if not do_close, do: file
  end
end
