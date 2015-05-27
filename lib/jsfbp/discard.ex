defmodule Jsfbp.Discard do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """

  def inports,  do: [IN: nil, OUT: nil]
  def outports, do: []

  def loop(in_port, out_pid) do
    receive do
      {:IN, :end} ->
        send(out_pid, :end)
      {:IN, value} ->
        loop(value, out_pid)
      {:OUT, value} ->
        loop(in_port, value)
    end
  end

end
