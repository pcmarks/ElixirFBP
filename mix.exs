defmodule ElixirFBP.Mixfile do
  # alias ElixirFBP.Network
  # alias ElixirFBP.Graph

  use Mix.Project

  def project do
    [app: :elixirFBP,
     version: "0.0.1",
     elixir: "~> 1.1",
     name: "ElixirFBP",
     source_url: "https://github.com/pcmarks/ElixirFBP",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [],
     registered: [ElixirFBP.Network, ElixirFBP.Graph]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    []
  end
end
