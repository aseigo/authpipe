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
      extra_applications: [:logger],
      mod: {Authpipe.Application, []}
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1.0"},
      {:remix, "~> 0.0.2", only: :dev},
      {:credo, "~> 0.8.1", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:test], runtime: false},
      {:coverex, "== 1.4.13", only: :test}
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
