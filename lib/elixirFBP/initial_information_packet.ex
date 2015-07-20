defmodule ElixirFBP.InitialInformationPacket do
  @moduledoc """
  A special component that can deliver a constant
  """
  def inports, do: []
  def outports, do: [:value, :any]
  def loop(_inports, outports) do
    %{:value => value} = outports
    receive do
      {:value, subscription_pid} ->
        send(subscription_pid, {:value, value})
    end
  end
end
