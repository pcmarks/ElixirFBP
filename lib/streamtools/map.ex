defmodule Streamtools.Map do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def inports, do: [in_port: nil, map: nil]
  def outports, do: [out: nil]

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
