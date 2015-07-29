defmodule Streamtools.Ticker do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  Send out a message every interval milliseconds
  TODO: Still not implemented correctly.
  """
  use Timex
  alias ElixirFBP.Component
  @behaviour ElixirFBP.Behaviour

  def description, do: "Emit a time stamp after a delay of interval milliseconds"
  def inports, do: [interval: :integer]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:interval => interval} = inports
    receive do
      {:interval, value} ->
        inports = %{inports | :interval => value}
        loop(inports, outports)
      :out when interval != nil ->
        Process.send_after(outports[:out],
                   {:out, DateFormat.format!(Date.now, "{RFC1123}")},
                   interval)
        send(self(), :out)
        loop(inports, outports)
    end
  end
end
