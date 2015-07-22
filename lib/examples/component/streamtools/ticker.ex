defmodule Streamtools.Ticker do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  Send out a message every interval milliseconds
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
      {:out, subscription} when interval != nil ->
        Stream.timer(interval) |> Enum.take(1)
        send(subscription, {:out, DateFormat.format!(Date.now, "{RFC1123}")})
        loop(inports, outports)
    end
  end
end
