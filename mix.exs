defmodule WeMo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wemo,
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
      {:httpoison, "~> 0.13.0", override: true},
      {:sweet_xml, "~> 0.6.5"},
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
      name: :wemo,
      files: ["lib", "mix.exs", "priv", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/wemo",
          "Docs" => "https://github.com/NationalAssociationOfRealtors/wemo"}
    ]
  end
end
