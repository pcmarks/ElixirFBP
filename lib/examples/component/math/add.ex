defmodule Math.Add do
  @moduledoc """
  This module describes an FBP Component: Math.Add
  """
  def description, do: "Add two integers"
  def inports, do: [addend: :integer, augend: :integer]
  def outports, do: [sum: :integer]

  def loop(inports, outports) do
    %{:augend => augend, :addend => addend} = inports
    %{:sum => sum} = outports
    receive do
      {:augend, value} when not is_nil(addend) ->
        sum = ElixirFBP.Component.send_ip(sum, addend + value)
        outports = %{outports | :sum => sum}
        inports = %{inports | :augend => nil, :addend => nil}
        loop(inports, outports)
      {:augend, value} ->
        inports = %{inports | :augend => value}
        loop(inports, outports)
      {:addend, value} when not is_nil(augend) ->
        sum = ElixirFBP.Component.send_ip(sum, value + augend)
        outports = %{outports | :sum => sum}
        inports = %{inports | :augend => nil, :addend => nil}
        loop(inports, outports)
      {:addend, value} ->
        inports = %{inports | :addend => value}
        loop(inports, outports)
    end
  end
end
