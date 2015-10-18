defmodule ElixirFBP.InitialInformationPacket do
  @moduledoc """
  A special component that can deliver a constant anytime it is sent
  a :value message.
  """
  @behaviour ElixirFBP.Behaviour

  def description, do: "An Initial Information Packet producer"
  def inports, do: [constant: :any]
  def outports, do: [value: :any]

  def loop(inports, outports) do
    %{:constant => value} = inports
    receive do
      :value ->
        send(outports[:value], {:value, value})
      loop(inports, outports)
    end
  end
end
