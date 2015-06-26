defmodule Streamtools.Unpack do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component
  @behavour ElixirFBP.Behaviour

  def description, do: "Take an array of objects and emit each object separately."
  def inports, do: [part: :string, in_port: :string]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:part => part, :in_port => in_port} = inports
    %{:out => out} = outports
    receive do
      {:part, value} ->
        inports = %{inports | :part => value}
        loop(inports, outports)
      {:in_port, value} ->
        inports = %{inports | :in_port => value}
        out = Component.send_ip(out, value[part])
        outports = %{outports | :out => out}
        loop(inports, outports)
    end
  end

end
