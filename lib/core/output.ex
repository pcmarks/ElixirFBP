defmodule Core.Output do

  def inports, do: [:in, :outports]
  def outports, do: []

  def loop(in_port, outports) do
    receive do
      {:in, value} ->
        IO.puts("\nCore.Output:in = #{inspect value}")
        loop(nil, nil)
    end
  end
end
