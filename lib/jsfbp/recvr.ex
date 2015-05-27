defmodule Jsfbp.Recvr do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  If, after @wait_time milliseconds a message is not received, it sends out a
  :no_data message
  """
  @nodata_time    5_000

  def inports,  do: [IN: nil, OUT: nil]
  def outports, do: []

  def loop(in_port, out_pid) do
    receive do
      {:OUT, value} ->
        loop(in_port, value)
      {:IN, data} ->
        IO.puts("data: #{data}")
        loop(in_port, out_pid)
      after @nodata_time ->
        send(out_pid, :no_data)
        loop(in_port, out_pid)
    end
  end

end
