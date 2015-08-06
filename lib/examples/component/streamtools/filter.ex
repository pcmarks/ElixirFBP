defmodule Streamtools.Filter do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component
  @behaviour ElixirFBP.Behaviour

  def description, do: "Filter according to a value."
  def inports, do: [filter: :string, filter_value: :string, in_port: :string]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:filter => filter, :filter_value => filter_value, :in_port => in_port} = inports
    receive do
      {:filter, value} ->
        inports = %{inports | :filter => value}
        loop(inports, outports)
      {:filter_value, value} ->
        inports = %{inports | :filter_value => value}
        loop(inports, outports)
      {:in_port, data} ->
        inports = %{inports | :in_port => data}
        loop(inports, outports)
      :out when in_port != nil ->
        out = Enum.filter(in_port, fn(in_port) ->
          in_port[filter] == filter_value end)
        send(outports[:out], {:out, out})
        inports = %{inports | :in_port => nil}
        loop(inports, outports)
    end
  end
end
