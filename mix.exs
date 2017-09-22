defmodule WeMo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wemo,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WeMo.Application, []},
      extra_applications: [:logger, :ssdp]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ssdp, "~> 0.1"},
      {:httpoison, "~> 0.13.0", override: true},
      {:plug, "~> 1.4"},
      {:plug_rest, "~> 0.13"},
    ]
  end
end
