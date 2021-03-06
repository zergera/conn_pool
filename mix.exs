defmodule ConnPool.Mixfile do
  use Mix.Project

  def project do
    [
      app: :conn_pool,
      name: "Conn.Pool",
      version: "0.3.0",
      description: """
        Connection pool helps storing, sharing and using connections. It also
        make its possible to use the same connection concurrently.
      """,
      elixir: "~> 1.6",
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      source_url: "https://github.com/zergera/conn_pool",
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [
      quality: [
        "format",
        "credo --strict"
      ]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.1"},
      {:earmark, "~> 1.2", only: :dev},
      {:agent_map, "~> 0.9"},
      {:ex_doc, "~> 0.18", only: :dev},
      {:credo, "~> 0.9", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Valentin Tumanov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/zergera/conn_pool",
        "Docs" => "http://hexdocs.pm/conn_pool"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/conn"]
  defp elixirc_paths(_), do: ["lib"]
end
