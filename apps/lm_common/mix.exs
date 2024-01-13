defmodule LmCommon.MixProject do
  use Mix.Project

  def project do
    [
      app: :lm_common,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LmCommon.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.16"},
      {:jason, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.1"},
      {:typed_struct, "~> 0.3.0"},
      {:ecto, "~> 3.10.0"}
    ]
  end
end
