defmodule FBPNetworkTest do
  use ExUnit.Case
  require Poison.Encoder

  test "a badly formatted message" do
    req = nil
    opts = nil
    message = Poison.Encoder.encode(~s("This is a test"), [])
    response = FBPNetwork.WsHandler.websocket_handle({:text, message}, req, opts)
    assert response == {:error, "Invalid message: #{message}"}
  end

  test "runtime protocol message" do
    req = nil
    opts = nil
    message = ~s({"protocol":"runtime","command":"getruntime","payload":{"secret":"122223333"}})
    response = FBPNetwork.WsHandler.websocket_handle({:text, message}, req, opts)
    fbp_message = ~s({"protocol":"runtime","payload":{"version":"0.0.1","type":"elixir-fbp","capabilities":["protocol:component","protocol:runtime","protocol:network"]},"command":"runtime"})
    expected = {:reply, {:text, fbp_message}, req, nil}
    assert response == expected
  end
end
