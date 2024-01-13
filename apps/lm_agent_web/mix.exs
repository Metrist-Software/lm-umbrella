defmodule LmAgentWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :lm_agent_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LmAgentWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:lm_web, in_umbrella: true},
      {:lm_agent, in_umbrella: true}
    ]
  end

  def releases do
    [
      lm_agent_web: [
        applications: [
          lm_agent_web: :permanent
        ],
        runtime_config_path: "../../config/agent-runtime.exs"
        # TODO: Uncomment this once we decided ship agent as an executable
        #         steps: [:assemble, &Burrito.wrap/1],
        #         burrito: [
        #           targets: [
        #            macos: [os: :darwin, cpu: :x86_64],
        #             linux: [os: :linux, cpu: :x86_64],
        #             windows: [os: :windows, cpu: :x86_64]
        #           ]
        #         ]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind lm_agent_web", "esbuild lm_agent_web"],
      "assets.deploy": ["tailwind lm_agent_web --minify", "esbuild lm_agent_web --minify", "phx.digest"]
    ]
  end
end
