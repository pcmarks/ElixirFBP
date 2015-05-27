defmodule Jsfbp.Sender do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Component

  def inports,  do: [COUNT: nil]
  def outports, do: [OUT: nil]

  def loop(_count, out) do
    receive do
      {:COUNT, value} ->
        for i <- 1..value do
          Component.send_ip(out, i)
        end
        loop(value, out)
    end
  end

end
