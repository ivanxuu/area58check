defmodule Area58check.Mixfile do
  use Mix.Project

  @github_url "https://github.com/ihinojal/area58check"

  def project do
    [
      app: :area58check,
      version: "0.1.0",
      elixir: "~> 1.5",
      description: description(),
      package: package(),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      source_url: @github_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  #── PRIVATE ──────────────────────────────────────────────────────────

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description do
    "Base58check library to encode binary data or decode encoded "<>
    "strings. It's used in Bitcoin whenever there is a need for a "<>
    "user to read or transcribe a number, such a bitcoin adresses, "<>
    "encrypted key, private key, or script hash."
  end

  defp package do
    [maintainers: ["Ivan H."],
     licenses: ["MIT"],
     links: %{"Github" => @github_url}]
  end

  defp docs do
    [
      main: "Area58check",
      # source_ref: "v#{@version}",
      # logo: "path/to/logo.png",
      extras: ["README.md"]
    ]
  end
end
