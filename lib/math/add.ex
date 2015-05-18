defmodule Math.Add do
  @moduledoc """
  This module describes an FBP Component: Math.Add
  It knows its input and outport ports and how to execute a function.
  Ports are described with tuples: {name, initial value}
  """
  def inports, do: [{:addend, nil}, {:augend, nil}]

  def outports, do: [{:sum, nil}]

  def execute do
    loop(nil, nil, nil)
  end

  def loop(augend, addend, sum) do
    receive do
      {:augend, value} when addend != nil ->
        send sum, addend + augend
        loop(nil, nil, sum)
      {:augend, value} -> loop(value, addend, sum)
      {:addend, value} when augend != nil ->
        send sum, addend + augend
        loop(nil, nil, sum)
      {:addend, value} -> loop(augend, value, sum)
      :stop -> nil
    end
  end
end
