defmodule Streamtools.Map do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def description, do: "Map inbound data onto outbound data"
  def inports, do: [in_port: :string, map: :string]
  def outports, do: [out: :string]

  def loop(in_port, map, out) do
    receive do
      {:map, value} ->
        loop(in_port, value, out)
      {:in_port, value} ->
        out = Component.send_ip(out, map)
        loop(value, map, out)
    end
  end

end
