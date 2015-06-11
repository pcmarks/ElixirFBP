defmodule FBPNetwork.FBPHandler do
  @moduledoc """
  FBPHandler contains functions that execute the Flow-Based Programming (FBP)
  Network Protocol commands. For more details see [here](http://noflojs.org/documentation/protocol/)

  The protocol is message-based; the transport layer for the messages acts
  asynchronously. A message consists of three parts: a protocol, a command and
  a payload

  There are four types of protocol:
    1. runtime
    2. network
    3. component
    4. graph

  Within each protocol, there are several commands. See the approriate
  fbp_handle function for their descriptions.

  """
  require Logger

  alias ElixirFBP.Network
  alias ElixirFBP.Graph
  alias ElixirFBP.Component

  @doc """
  Execute a runtime protocol command.
    Commands:
      getruntime - request information about the runtime
        payload: {secret}
      runtime - response to getruntime command
        payload: {version, type, capabilities, id, label, graph}
  """

  def fbp_handle("runtime", command, payload, req, state) do
    Logger.info("runtime: #{command} / #{inspect payload}")
    response =
      case command do
        "getruntime" ->
            # Capabilities:
            #     1. the runtime is able to list and modify its components using the Component protocol
            #     2. the runtime is able to expose the ports of its main graph using the Runtime protocol
            #        and transmit packet information to/from them
            #     3. the runtime is able to control and introspect its running networks using the Network
            #        protocol
            capabilities = ["protocol:component", "protocol:runtime", "protocol:network"]
            payload = %{"version" => "0.0.1", "type" => "elixir-fbp", "capabilities" => capabilities}
            %{ "command" => "runtime", "protocol" => "runtime", "payload" => payload}
        _ ->
          Logger.warn("unknown command: #{command}")
          nil
      end
    fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    {:reply, {:text, fbp_message}, req, state}
  end

  @doc """
  Execute a graph protocol command.
    Commands:
      addnode -
        payload: {id, component, metadata, graph, secret}
      removenode -
        payload: {id, graph, secret}
      renamenode -
        payload: {id, graph, secret}
      changenode -
        payload: {id, metadata, graph, secret}
      addedge -
        payload: {src, tgt, metadata, graph, secret}
      removeedge -
        payload: {src, tgt, graph, secret}
      addinitial -
        payload: {src, tgt, metadata, graph, secret}
      removeinitial -
        payload: {tgt, graph, secret}
      addinport -
        payload: {public, node, port, metadata, graph, secret}

  """
  def fbp_handle("graph", command, payload, req, state) do
    Logger.info("graph: #{command} / #{inspect payload}")
    {new_state, response} =
      case command do
        "addnode" ->
          %{"id" => id, "component" => component, "metadata" => metadata,
            "graph" => graph} = payload
          {Network.add_node(state, graph, id, component, metadata), nil}
        "addinitial" ->
          %{"src" => src, "tgt" => tgt, "graph" => graph} = payload
          Network.add_initial(state, graph, src, tgt)
          nil
        _ ->
          Logger.warn("Graph command not handled: #{inspect command}")
          nil
      end
    fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    {:reply, {:text, fbp_message}, req, new_state}
  end

  @doc """
  Execute a component protocol command.
    Commands:
      component -
        payload:
  """
  def fbp_handle("component", command, payload, req, state) do
    Logger.info("component: #{command} / #{inspect payload}")
    secret = Map.get(payload, "secret")
    response =
      case command do
        "list" ->
          outPorts = [%{"type" => "integer", "id" => "out"}]
          inPorts  = [%{"type" => "integer", "id" => "in"}]
          name = "ElixirFBP.IncrementByOne"
          description = "Increment by one in Elixir!"
          payload = %{"outPorts" => outPorts, "inPorts" => inPorts, "name" => name, "description" => description}
          %{"protocol" => "component", "command" => "component", "payload" => payload}
        _ ->
          Logger.warn("Component command not handled: #{inspect command}")
          nil
      end
    fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    {:reply, {:text, fbp_message}, req, state}
  end

  @doc """
  Execute a network protocol command.
  """
  def fbp_handle("network", command, payload, req, state) do
    Logger.info("network: #{command} / #{inspect payload}")
    graph = Map.get(payload, "graph")
    secret = Map.get(payload, "secret")
    response =
      case command do
        "getstatus" ->
          Network.get_status(graph, secret)
        "debug" ->
          {:ok, registered_name} = Network.get_graph(graph)
          if ! registered_name do
            Network.clear(graph)
          end
          Network.set_debug(Map.get(payload, "enable"))
          nil
        _ ->
          Logger.warn("Network command not handled: #{inspect command}")
          nil
      end
      if response do
        fbp_message = response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
      else
        fbp_message = nil
      end
    {:reply, {:text, fbp_message}, req, state}
  end

  @doc """
  Fall through
  """
  def fbp_handle(protocol, _command, _payload, _req, _state) do
    {:error, "unknown protocol: #{inspect protocol}"}
  end
end
