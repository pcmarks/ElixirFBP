defmodule FBPNetwork.WsHandler do
  require Poison.Parser
  require Poison.Encoder

  @behaviour :cowboy_websocket_handler

  @doc """
  By returning :upgrade Cowboy will switch to web socket mode
  """
  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @doc """
  Called just before switching to websocket mode. Register this process as a
  client with the ElixirFBP Runtime server process
  """
  def websocket_init(_transport_name, req, _opts) do
    state = HashDict.new()
    ElixirFBP.Runtime.register_client(self())
    {:ok, req, state}
  end

  def websocket_handle({:text, msg}, req, state) do
    fbp_message = Poison.Parser.parse!(msg)
    case fbp_message do
      %{"protocol" => protocol, "command" => command, "payload" => payload} ->
        FBPNetwork.FBPHandler.fbp_handle(protocol, command, payload, req, state)
      _ ->
        {:error, "Invalid message: #{msg}"}
    end
  end

  def websocket_handle(_data, req, state) do
    {:ok, req, state}
  end

  @doc """
  Somebody in the FBP Network has sent us a message. Pass it on, correctly
  formatted.
  """
  def websocket_info({:output, message}, req, state) do
    payload = %{"message" => message, "type" => "message"}
    response = %{"protocol" => "network", "command" => "output", "payload" => payload}
    fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    {:reply, {:text, fbp_message}, req, state}
  end

  @doc """
  Somebody in the FBP Network has sent us an error. Pass it on, correctly
  formatted.
  """
  def websocket_info({:error, message}, req, state) do
    payload = %{"message" => message}
    response = %{"protocol" => "network", "command" => "error", "payload" => payload}
    fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    {:reply, {:text, fbp_message}, req, state}
  end

  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    # Unregister the Runtime client to us
    ElixirFBP.Runtime.register_client(nil)
    :ok
  end
end
