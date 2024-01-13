defmodule LmBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :lm_backend,
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
      mod: {LmBackend.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:lm_common, in_umbrella: true},
      {:configparser_ex, "~> 4.0"},
      {:ecto_sql, "~> 3.6"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:hackney, "~> 1.18"},
      {:libcluster, "~> 3.3"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
