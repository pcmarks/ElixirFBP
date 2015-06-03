defmodule Streamtools.Ticker do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  Send out a message every interval milliseconds
  """
  use Timex
  alias ElixirFBP.Component

  def inports, do: [interval: nil]
  def outports, do: [out: nil]

  def loop(interval, out) do
    receive do
      {:interval, value} ->
        loop(value, out)
      after 10_000 ->
        out = Component.send_ip(out, DateFormat.format!(Date.now, "{RFC1123}"))
        loop(interval, out)
    end
  end
end
