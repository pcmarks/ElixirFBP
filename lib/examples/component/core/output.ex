defmodule Core.Output do

  def description, do: "Show the IP in the Console"
  def inports, do: [in_port: :string]
  def outports, do: []

  def loop(in_port) do
    receive do
      {:in_port, value} ->
        IO.puts("\nCore.Output:in = #{inspect value}")
        loop(nil)
    end
  end
end
