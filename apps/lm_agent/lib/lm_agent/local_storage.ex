defmodule LmAgent.LocalStorage do
  @moduledoc """
  Local metrics storage. This stores metrics (and reads them back) in the
  directory identified by `LmAgent.data_dir()`.

  Storage mechanism is very straightforward for now, we can always soup it up. Therefore,
  the first file we drop is a version number so we can easily evolve storage.
  """

  @version 0

  @doc """
  Initialize storage, make sure all is well. Will raise various errors if we can't write
  to the data directory, etc.
  """
  def initialize(), do: initialize(LmAgent.data_dir())

  def initialize(data_dir) do
    File.mkdir_p!(data_dir)
    assert_current_version(data_dir)
  end

  defdelegate open_for_write(dir, name, day, opts \\ []), to: LmAgent.LocalStorage.File
  defdelegate open_for_read(dir, name, day), to: LmAgent.LocalStorage.File
  defdelegate write(file, time, value, tags), to: LmAgent.LocalStorage.File
  defdelegate read(file), to: LmAgent.LocalStorage.File
  defdelegate close(file), to: File

  defp assert_current_version(data_dir) do
    vf = version_file(data_dir)
    if File.exists?(vf) do
      stored_version =
        vf
        |> File.read!()
        |> String.trim()
        |> String.to_integer()
      if stored_version != @version do
        # And at some point, we'll migrate for you :)
        raise "Incompatible storage version in #{data_dir}. Please migrate."
      end
    else
      File.write!(vf, "#{@version}")
    end
  end

  defp version_file(data_dir), do: Path.join(data_dir, "version.txt")
end
