defmodule FBPNetwork.WsHandler do
  require Poison.Parser
  require Poison.Encoder

  @behaviour :cowboy_websocket_handler

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, _opts) do
    state = HashDict.new()
    {:ok, req, state}
  end

  def websocket_handle({:text, msg}, req, state) do
    fbp_message = Poison.Parser.parse!(msg)
    case fbp_message do
      %{"protocol" => protocol, "command" => command, "payload" => payload} = fbp_message ->
        FBPNetwork.FBPHandler.fbp_handle(protocol, command, payload, req, state)
      _ ->
        {:error, "Invalid message: #{msg}"}
    end
  end

  def websocket_handle(_data, req, state) do
    {:ok, req, state}
  end

  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
