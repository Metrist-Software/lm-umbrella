defmodule LmAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :lm_agent,
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
      mod: {LmAgent.Application, []},
      extra_applications: [:logger, :os_mon]
    ]
  end

  # Run "mix help deps" to learn about dependencie.
  defp deps do
    [
      {:finch, "~> 0.16"},
      {:prometheus_parser, github: "Metrist-Software/turnio-prometheus-parser", branch: "tweaks"},
      {:lm_common, in_umbrella: true},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_metrics_statsd, "~> 0.6.0"},
      {:telemetry_poller, "~> 1.0"},
      {:typed_struct, "~> 0.3.0"},
      {:slipstream, "~> 1.0"},
      {:iteraptor, "~> 1.14.0"},
      {:cachex, "~> 3.6"},
      {:ecto, "~> 3.10.0"}
    ]
  end
end
