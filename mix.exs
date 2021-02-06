defmodule Preview.MixProject do
  use Mix.Project

  def project do
    [
      app: :preview,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Preview.Application, []},
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
      {:broadway, "~> 0.6.2"},
      {:broadway_sqs, "~> 0.6.1"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:finch, "~> 0.6.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:gettext, "~> 0.11"},
      {:goth, "~> 1.0"},
      {:hex_core, "~> 0.7.0"},
      {:jason, "~> 1.0"},
      {:logster, "~> 1.0"},
      {:mint, "~> 1.1"},
      {:makeup, "~> 1.0"},
      {:makeup_elixir, "~> 0.15.0"},
      {:makeup_erlang, "~> 0.1.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.15.0"},
      {:phoenix, "~> 1.5.4"},
      {:plug_cowboy, "~> 2.0"},
      {:rollbax, "~> 0.11.0"},
      {:sweet_xml, "~> 0.6.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "run priv/seeds.exs", "cmd yarn install --cwd assets"]
    ]
  end

  defp releases do
    [preview: [include_executables_for: [:unix]]]
  end
end
