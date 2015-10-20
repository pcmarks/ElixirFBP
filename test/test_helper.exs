ExUnit.start(trace: true)

# Define some basic ElixirFBP Components that will be used in the examples

defmodule Core.Log do

  @behaviour ElixirFBP.Behaviour

    require Logger

    def description, do: "Log the IP"
    def inports, do: [in_port: :string]
    def outports, do: []

    def loop(inports, outports) do
      receive do
        {:in_port, value} when value != nil ->
          Logger.info("#{inspect value}")
          loop(inports, outports)
      end
    end
end

defmodule Core.Output do

  @behaviour ElixirFBP.Behaviour

    def description, do: "Show the IP on the console"
    def inports, do: [in_port: :string]
    def outports, do: []

    def loop(inports, outports) do
      receive do
        {:in_port, value} when value != nil ->
          IO.puts("#{inspect value}")
          loop(inports, outports)
      end
    end
end

defmodule Math.Add do
  @moduledoc """
  This module describes an FBP Component: Math.Add
  """
  @behaviour ElixirFBP.Behaviour

  def description, do: "Add two integers"
  def inports, do: [addend: :integer, augend: :integer]
  def outports, do: [sum: :integer]

  def loop(inports, outports) do
    %{:augend => augend, :addend => addend} = inports
    receive do
      {:addend, value} when is_number(augend)->
        send(outports[:sum], {:sum, value + augend})
        inports = %{inports | :addend => nil, :augend => nil}
        loop(inports, outports)
      {:addend, value} ->
        inports = %{inports | :addend => value}
        loop(inports, outports)
      {:augend, value} when is_number(addend) ->
        send(outports[:sum], {:sum, addend + value})
        inports = %{inports | :addend => nil, :augend => nil}
        loop(inports, outports)
      {:augend, value} ->
        inports = %{inports | :augend => value}
        loop(inports, outports)
      :sum when is_number(addend) and is_number(augend) ->
        send(outports[:sum], {:sum, addend + augend})
        inports = %{inports | :addend => nil, :augend => nil}
        loop(inports, outports)
    end
  end
end
