defmodule WeMo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_wemo,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WeMo.Application, []},
      env: [http_port: 8083],
      extra_applications: [:logger, :ssdp, :sweet_xml]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ssdp, "~> 0.1"},
      {:httpoison, "~> 0.11.1"},
      {:sweet_xml, "~> 0.6.5"},
      {:cowboy, "~> 1.0"},
      {:html_entities, "~> 0.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  def description do
    """
    Discover, monitor and control Belkin WeMo devices on your local network
    """
  end

  def package do
    [
      name: :ex_wemo,
      files: ["lib", "mix.exs", "priv", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/ex_wemo",
          "Docs" => "https://github.com/NationalAssociationOfRealtors/ex_wemo"}
    ]
  end
end
