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
    %{:out => out} = outports
    receive do
      {:filter, value} ->
        inports = %{inports | :filter => value}
        loop(inports, outports)
      {:filter_value, value} ->
        inports = %{inports | :filter_value => value}
        loop(inports, outports)
      {:in_port, data} when out == nil ->
        out = Enum.filter(data, fn(datum) ->
          datum[filter] == filter_value end)
        outports = %{outports | :out => out}
        loop(inports, outports)
      {:out, subscription} when out != nil ->
        send(subscription, {:out, out})
        outports = %{outports | :out => nil}
        loop(inports, outports)
    end
  end
end
