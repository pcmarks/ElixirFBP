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
      {:addend, value} ->
        inports = %{inports | :addend => value}
        loop(inports, outports)
      {:augend, value} ->
        inports = %{inports | :augend => value}
        loop(inports, outports)
      :sum when is_number(addend) and is_number(augend) ->
        send(outports[:sum], {:sum, addend + augend})
        loop(inports, outports)
    end
  end
end
