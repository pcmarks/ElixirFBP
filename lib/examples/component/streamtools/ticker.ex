defmodule Streamtools.Ticker do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  Send out a message every interval milliseconds
  TODO: THIS IS NOT IMPLEMENTED CORRECTLY!!
  """
  use Timex
  alias ElixirFBP.Component
  @behaviour ElixirFBP.Behaviour

  def description, do: "Emit a time stamp periodically"
  def inports, do: [interval: :integer]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:interval => interval} = inports
    %{:out => out} = outports
    receive do
      {:interval, value} ->
        inports = %{inports | :interval => value}
        loop(inports, outports)
      after 10_000 ->
        out = Component.send_ip(out, DateFormat.format!(Date.now, "{RFC1123}"))
        outports = %{outports | :out => out}
        loop(inports, outports)
    end
  end
end
