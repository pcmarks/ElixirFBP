defmodule FBPNetworkTest do
  use ExUnit.Case
  require Poison.Encoder

  alias ElixirFBP.Network

  test "a badly formatted message" do
    req = nil
    opts = nil
    message = Poison.Encoder.encode(~s("This is a test"), [])
    response = FBPNetwork.WsHandler.websocket_handle({:text, message}, req, opts)
    assert response == {:error, "Invalid message: #{message}"}
  end

  test "runtime/runtime protocol message" do
    req = nil
    opts = nil
    message = ~s({"protocol":"runtime","command":"getruntime","payload":{"secret":"122223333"}})
    response = FBPNetwork.WsHandler.websocket_handle({:text, message}, req, opts)
    fbp_message = ~s({"protocol":"runtime","payload":{"version":"0.0.1","type":"elixir-fbp","capabilities":["protocol:component","protocol:runtime","protocol:network"]},"command":"runtime"})
    expected = {:reply, {:text, fbp_message}, req, nil}
    assert response == expected
  end

  test "network/debug protocol message" do
    req = nil
    opts = nil
    Network.start_link
    message = ~s({"protocol":"network","command":"debug","payload":{"graph": "foobar", "enable": true, "secret":"122223333"}})
    response = FBPNetwork.WsHandler.websocket_handle({:text, message}, req, opts)
    expected = {:reply, {:text, ""}, req, nil}
    assert response == expected
  end
end
