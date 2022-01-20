defmodule Eventstore.Dashboard.MixProject do
  use Mix.Project

  @version "0.0.1"
  @description "A Phoenix LiveDashboard page for inspecting your EventStore databases"

  def project do
    [
      aliases: aliases(),
      app: :eventstore_dashboard,
      deps: deps(),
      description: @description,
      docs: docs(),
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "https://github.com/commanded/eventstore-dashboard",
      name: "EventStoreDashboard",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      dev: "run --no-halt dev.exs"
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env()),
      mod: {EventStore.Dashboard.Application, []}
    ]
  end

  defp deps do
    [
      # {:eventstore, ">= 1.4.0"},
      {:eventstore, github: "commanded/eventstore"},
      {:jason, "~> 1.2", only: [:dev, :test, :docs]},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:plug_cowboy, "~> 2.5", only: :dev},

      # Development & test tools
      {:ex_doc, "~> 0.25", only: :docs},
      {:floki, "~> 0.32", only: :test}
    ]
  end

  defp docs do
    [
      main: "EventStore.Dashboard",
      source_ref: "v#{@version}",
      source_url: "https://github.com/commanded/eventstore_dashboard",
      nest_modules_by_prefix: [EventStore.Dashboard]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp extra_applications(:dev), do: [:logger, :runtime_tools, :os_mon]
  defp extra_applications(_env), do: [:logger]

  defp package do
    [
      files: ["lib", "guides", "mix.exs", "CHANGELOG.md", "README.md", "LICENSE.md"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/commanded/eventstore-dashboard"
      },
      maintainers: ["Ben Smith"]
    ]
  end
end
