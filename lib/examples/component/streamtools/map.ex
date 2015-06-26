defmodule Streamtools.Map do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component
  @behaviour ElixirFBP.Component

  def description, do: "Map inbound data onto outbound data"
  def inports, do: [in_port: :string, map: :string]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:in_port => in_port, :map => map} = inports
    %{:out => out} = outports
    receive do
      {:map, value} ->
        inports = %{inports | :map => value}
        loop(inports, outports)
      {:in_port, value} ->
        inports = %{inports | :in_port => value}
        out = Component.send_ip(out, map)
        outports = %{outports | :out => out}
        loop(inports, outports)
    end
  end

end
