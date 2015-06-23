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
    secret = Map.get(payload, "secret")
    {new_state, response} =
      case command do
        "addnode" ->
          %{"id" => id, "component" => component, "metadata" => metadata,
            "graph" => graph_id} = payload
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.add_node(graph_reg_name, id, component, metadata)
          {state, nil}
        "removenode" ->
          %{"id" => id, "graph" => graph_id} = payload
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.remove_node(graph_reg_name, id)
          {state, nil}
        "renamenode" ->
          %{"from" => from, "to" => to, "graph" => graph_id} = payload
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.rename_node(graph_reg_name, from, to, secret)
          {state, nil}
        "changenode" ->
          %{"id" => id, "metadata" => metadata, "graph" => graph_id} = payload
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.change_node(graph_reg_name, id, metadata, secret)
          {state, nil}
        "addinitial" ->
          %{"src" => src, "tgt" => tgt, "graph" => graph_id} = payload
          %{"data" => data} = src
          %{"node" => node_id, "port" => port} = tgt
          graph_reg_name = get_graph_registered_name(graph_id)
          message = Graph.add_initial(graph_reg_name, data, node_id, String.to_atom(port))
          {state, message}
        "removeinitial" ->
          %{"tgt" => tgt, "graph" => graph_id} = payload
          %{"node" => tgt_node, "port" => tgt_port} = tgt
          graph_reg_name = get_graph_registered_name(graph_id)
          message = Graph.remove_initial(graph_reg_name, tgt_node,
                String.to_atom(tgt_port), secret)
          {state, message}
        "addedge" ->
          %{"src" => src, "tgt" => tgt, "graph" => graph_id} = payload
          %{"node" => src_node, "port" => src_port} = src
          %{"node" => tgt_node, "port" => tgt_port} = tgt
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.add_edge(graph_reg_name, src_node, String.to_atom(src_port),
                                          tgt_node, String.to_atom(tgt_port))
          {state, nil}
        "removeedge" ->
          %{"src" => src, "tgt" => tgt, "graph" => graph_id} = payload
          %{"node" => src_node, "port" => src_port} = src
          %{"node" => tgt_node, "port" => tgt_port} = tgt
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.remove_edge(graph_reg_name, src_node, String.to_atom(src_port),
                                          tgt_node, String.to_atom(tgt_port))
          {state, nil}
        "changeedge" ->
          %{"src" => src, "tgt" => tgt, "graph" => graph_id,
            "metadata" => metadata} = payload
          %{"node" => src_node, "port" => src_port} = src
          %{"node" => tgt_node, "port" => tgt_port} = tgt
          graph_reg_name = get_graph_registered_name(graph_id)
          Graph.change_edge(graph_reg_name, src_node, String.to_atom(src_port),
                                          tgt_node, String.to_atom(tgt_port),
                                          metadata, secret)
          {state, nil}
        _ ->
          Logger.warn("Graph command not handled: #{inspect command}")
          {state, nil}
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
    responses =
      case command do
        "list" ->
          # Ask the Runtime for a list of the components that it knows about
          components = ElixirFBP.Runtime.get_parameter(:components)
          # Format the web socket response
          response = Enum.map(components, fn(component) ->
            %{"protocol" => "component", "command" => "component", "payload" => component}
          end)
          response ++
           [%{"protocol" => "component", "command" => "componentsready",
           "payload" => to_string(length(response))}]
        _ ->
          Logger.warn("Component command not handled: #{inspect command}")
          nil
      end
    if responses != nil do
      fbp_message = Enum.map(responses, fn(response) ->
        {:text, response |> Poison.Encoder.encode([]) |> IO.iodata_to_binary}
      end)
    else
      fbp_message = nil
    end
    {:reply, fbp_message, req, state}
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
          {:ok, registered_name} = Network.get_graph(graph)
          if ! registered_name do
            Network.clear(graph)
          end
          {running, started} = Network.get_status(graph, secret)
          %{"graph" => graph, "running" => running, "started" => started}
        "start" ->
          start_time = :calendar.universal_time |> inspect
          case Network.start(graph) do
            :ok ->
                command = "started"
                payload = %{"graph" => graph, "time" => start_time,
                      "running" => true, "started" => true}
            error ->
                command = "error"
                payload = %{"message" => inspect error}
          end
          %{"protocol" => "network", "command" => command, "payload" => payload}
        "stop" ->
          stop_time = :calendar.universal_time |> inspect
          Network.stop(graph)
          payload = %{"graph" => graph, "time" => stop_time, "running" => false,
                      "started" => true}
          %{"protocol" => "network", "command" => "stopped", "payload" => payload}
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
        fbp_message = ""
      end
    {:reply, {:text, fbp_message}, req, state}
  end

  @doc """
  Fall through
  """
  def fbp_handle(protocol, _command, _payload, _req, _state) do
    {:error, "unknown protocol: #{inspect protocol}"}
  end


  defp get_graph_registered_name(graph_id) do
    {:ok, graph_reg_name} = Network.get_graph(graph_id)
    if graph_reg_name == nil do
      {:ok, graph_reg_name} = Network.clear(graph_id)
    end
    graph_reg_name
  end

end
