defmodule LmCommon do

  @doc """
  Return current day number since the Unix Epoch.
  """
  def day_num(%DateTime{} = dt), do: day_num(DateTime.to_unix(dt, :second))
  def day_num(num), do: div(num, 86_400)

  @doc """
  If available, return the current build information for the application.
  """
  def build_txt(application) do
    build_txt = Path.join([Application.app_dir(application), "priv", "static", "build.txt"])
    if File.exists?(build_txt) do
      File.read!(build_txt)
    else
      "(no build file, localdev?)"
    end
  end

  @doc """
  Sets global metadata for the umbrella app to include in logging
  Should be called in application start with the application module
  See https://elixirforum.com/t/add-global-metadata-to-the-logger/39987/2
  """
  def set_umbrella_app_logger_metadata(module) do
    :logger.update_primary_config(%{metadata: %{app: Application.get_application(module)}})
  end

end
