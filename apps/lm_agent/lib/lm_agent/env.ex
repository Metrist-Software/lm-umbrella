defmodule LmAgent.Env do
  def data_dir do
    case {System.get_env("LM_AGENT_DATA_DIR"), System.get_env("XDG_DATA_HOME"), System.get_env("USER")} do
      {directory, _, _} when is_binary(directory) -> directory
      {nil, directory, _} when is_binary(directory) -> :filename.basedir(:user_data, "lm_agent")
      {nil, nil, "root"} -> "/var/lib/lm_agent"
      {nil, nil, _} -> Path.expand("~/.local/share/lm_agent")
    end
  end
end
