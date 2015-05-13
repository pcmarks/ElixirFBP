defmodule Math.Add do
  @moduledoc """
  This module describes an FBP Component: Math.Add
  It knows its input and outport ports and how to execute a function.
  Ports are described with tuples: {name, initial value}
  """
  def inports, do: [{:addend, nil}, {:augend, nil}]
  def outports, do: [{:sum, nil}]
  def execute do
  end
end
