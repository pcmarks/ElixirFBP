defmodule Jsfbp.Reader do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Component

  def inports,  do: [FILE: nil]
  def outports, do: [OUT: nil]

  def loop(file, out) do
    receive do
      {:FILE, value} ->
        file_stream = File.stream!(value)
        Enum.each(file_stream, fn(line) -> Component.send_ip(out, line) end)
        Component.send_ip(out, :end)
        loop(value, out)
    end
  end

end
