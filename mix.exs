defmodule Preview.MixProject do
  use Mix.Project

  def project do
    [
      app: :preview,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Preview.Application, []},
      extra_applications: [:logger, :runtime_tools, :eex]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:broadway_sqs, "~> 0.7.0"},
      {:broadway, "~> 1.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws, "~> 2.1"},
      {:finch, "~> 0.16.0"},
      {:gettext, "~> 0.11"},
      {:goth, "~> 1.3-rc"},
      {:hex_core, "~> 0.8"},
      {:jason, "~> 1.0"},
      {:logster, "~> 1.0"},
      {:makeup_eex, "~> 0.1.2"},
      {:makeup_elixir, "~> 0.16.0"},
      {:makeup_erlang, "~> 0.1.0"},
      {:makeup, "~> 1.0"},
      {:mint, "~> 1.1"},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:rollbax, "~> 0.11.0"},
      {:sweet_xml, "~> 0.7.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "run priv/seeds.exs", "cmd yarn install --cwd assets"]
    ]
  end

  defp releases do
    [
      preview: [
        include_executables_for: [:unix],
        reboot_system_after_config: true
      ]
    ]
  end
end
