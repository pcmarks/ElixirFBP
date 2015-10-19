defmodule Core.Log do

  require Logger

  def description, do: "Log the IP"
  def inports, do: [in_port: :string]
  def outports, do: []

  def loop(inports, outports) do
    %{:in_port => in_port} = inports
    receive do
      {:in_port, value} when value != nil ->
        Logger.info("#{inspect value}")
        loop(inports, outports)
    end
  end
end
