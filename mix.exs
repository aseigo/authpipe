defmodule Authpipe.Mixfile do
  use Mix.Project

  def project do
    [
      app: :authpipe,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: Coverex.Task]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # core deps

      # stage deps
      {:ecto, "~> 2.2.10"},
      {:comeonin, "~>4.1.1"},
      {:argon2_elixir, "~> 1.3"},

      # development deps
      {:remix, "~> 0.0.2", only: :dev},
      {:credo, "~> 0.9.3", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:test], runtime: false},
      {:coverex, "~> 1.4.15", only: :test},
      {:jason, "~> 1.1.0", only: :test},
    ]
  end

  def aliases do
    [
      t: [&run_tests/1, "dialyzer", "credo"]
    ]
  end

  defp run_tests(_) do
    Mix.env(:test)
    Mix.Tasks.Test.run(["--cover", "--stale"])
  end
end
