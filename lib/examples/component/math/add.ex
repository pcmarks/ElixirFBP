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
    %{:sum => sum} = outports
    receive do
      {:addend, value} ->
        inports = %{inports | :addend => value}
        loop(inports, outports)
      {:augend, value} ->
        inports = %{inports | :augend => value}
        loop(inports, outports)
      {:sum, subscription_pid} when is_number(addend) and is_number(augend) ->
        sum = addend + augend
        outports = %{outports | :sum => sum}
        send(subscription_pid, {:sum, sum})
        loop(inports, outports)
    end
  end
end
