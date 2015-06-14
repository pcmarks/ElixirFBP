defmodule Math.Add do
  @moduledoc """
  This module describes an FBP Component: Math.Add
  """
  def description, do: "Add two integers"
  def inports, do: [addend: nil, augend: nil]
  def outports, do: [sum: nil]

  def loop(augend, addend, sum) do
    # IO.puts("Math.Add.loop(#{inspect augend},#{inspect addend}, #{inspect sum})")
    receive do
      {:augend, value} when addend != nil ->
        IO.puts("Math.Add: {:augend, #{value}}")
        sum = ElixirFBP.Component.send_ip(sum, addend + value)
        loop(nil, nil, sum)
      {:augend, value} ->
        IO.puts("Math.Add: {:augend, #{value}}")
        loop(value, addend, sum)
      {:addend, value} when augend != nil ->
        IO.puts("Math.Add: {:addend, #{value}}, augend: #{augend}")
        sum = ElixirFBP.Component.send_ip(sum, value + augend)
        loop(nil, nil, sum)
      {:addend, value} ->
        IO.puts("Math.Add: {:addend, #{value}}")
        loop(augend, value, sum)
    end
  end
end
