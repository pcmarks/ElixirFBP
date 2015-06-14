defmodule Jsfbp.Sender do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Component

  def inports,  do: [COUNT: :integer]
  def outports, do: [OUT: :integer]

  def loop(last, out) do
    receive do
      {:COUNT, value} ->
        count_loop(value, 1, out)
    end
  end

  def count_loop(last, current, out) when current <= last do
    out = Component.send_ip(out, current)
    count_loop(last, current + 1, out)
  end
  def count_loop(last, _, out) do
    out = Component.send_ip(out, :end)
    loop(last, out)
  end

end
