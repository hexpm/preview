defmodule Preview.MixProject do
  use Mix.Project

  def project do
    [
      app: :preview,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
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
      {:bandit, "~> 1.0"},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:broadway_sqs, "~> 0.7.0"},
      {:broadway, "~> 1.0"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws, "~> 2.1"},
      {:finch, "~> 0.22.0"},
      {:gettext, "~> 1.0"},
      {:goth, "~> 1.4"},
      {:hackney, "~> 1.20"},
      {:hex_core, "~> 0.17.0"},
      {:jason, "~> 1.0"},
      {:logster, "~> 1.1.1"},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},
      {:makeup, "~> 1.2"},
      {:makeup_eex, "~> 2.0"},
      {:makeup_elixir, "~> 1.0"},
      {:makeup_erlang, "~> 1.0"},
      {:makeup_gleam, "~> 1.0"},
      {:makeup_syntect, "~> 0.1"},
      {:mint, "~> 1.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:req, "~> 0.5"},
      {:sentry, "~> 13.0"},
      {:sweet_xml, "~> 0.7.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "run priv/seeds.exs", "esbuild.install", "tailwind.install"],
      "assets.deploy": [
        "esbuild preview --minify",
        "tailwind default --minify",
        "phx.digest"
      ]
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
