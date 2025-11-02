defmodule Waffle.Mixfile do
  use Mix.Project

  @version "1.1.9"

  def project do
    [
      app: :waffle,
      version: @version,
      elixir: "~> 1.4",
      source_url: "https://github.com/elixir-waffle/waffle",
      deps: deps(),
      docs: docs(),

      # Hex
      description: description(),
      package: package()
    ]
  end

  defp description do
    """
    Flexible file upload and attachment library for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["Boris Kuznetsov"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/elixir-waffle/waffle"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "documentation/examples/local.md",
        "documentation/examples/s3.md",
        "documentation/livebooks/custom_transformation.livemd"
      ]
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        # Used by Mix.generator.embed_template/2
        :eex
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev},
      {:mock, "~> 0.3", only: :test},
      {:hackney, "~> 1.9", only: [:dev, :test]},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
