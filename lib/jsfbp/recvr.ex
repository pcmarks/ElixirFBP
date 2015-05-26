defmodule Jsfbp.Recvr do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Component

  def inports,  do: [IN: nil]
  def outports, do: []

  def loop(in_port) do
    receive do
      {:IN, data} ->
        IO.puts("data: #{data}")
        loop(in_port)
    end
  end

end
