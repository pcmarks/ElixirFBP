defmodule Streamtools.Unpack do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def description, do: "Take an array of objects and emit each object separately."
  def inports, do: [part: :string, in_port: :string]
  def outports, do: [out: :string]

  def loop(part, in_port, out) do
    receive do
      {:part, value} ->
        loop(value, in_port, out)
      {:in_port, value} ->
        out = Component.send_ip(out, value[part])
        loop(part, value, out)
    end
  end

end
