defmodule Core.Output do

  def description, do: "Show the IP in the Console"
  def inports, do: [in_port: :string]
  def outports, do: []

  def loop(inports, outports) do
    %{:in_port => in_port} = inports
    receive do
      {:in_port, value} when value != nil ->
        IO.puts("\nCore.Output:in_port = #{inspect value}")
        loop(inports, outports)
    end
  end
end
