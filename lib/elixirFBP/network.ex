defmodule ElixirFBP.Network do
  @moduledoc """
  ElxirFBP.Network is a GenServer that provides support for starting and stopping
  FBP networks(graphs), and finding out about their state.

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the network sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details.

  This module is registered with its module name.

  It is assumed that the ElixirFBP.Graph GenServer, which becomes this servers
  state, has been started and registered with its id as its name.

  TODO: Finish implementation of data function

  """
  defstruct [
    graph_reg_name: nil,
    status: :stopped
  ]

  use GenServer

  alias ElixirFBP.Graph
  alias ElixirFBP.Component

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the state. The argument is the FBP
  Graph registered process name.
  """
  def start_link(fbp_graph_reg_name) do
    GenServer.start_link(__MODULE__, fbp_graph_reg_name, name: __MODULE__)
  end

  @doc """
  Start execution of the graph
  """
  def start do
    GenServer.cast(__MODULE__, :start)
  end

  @doc """
  Stop the execution of the graph
  """
  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  @doc """
  Get the networks current status
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc """
  Data transmission on an edge.
  """
  def data(graph_id, edge_id, src, tgt, subgraph \\ nil) do
    GenServer.cast(__MODULE__, {:data, graph_id, edge_id, src, tgt, subgraph})
  end

  @doc """
  Stop the Network GenServer process
  """
  def stop_network do
    GenServer.call(__MODULE__, :stop_network)
  end

  ########################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Network.start_link()
  Initialize the state with an FBP graph.
  """
  def init(fbp_graph_reg_name) do
    {:ok, %ElixirFBP.Network{graph_reg_name: fbp_graph_reg_name}}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.start()
  Starting a network involves the following steps:
    1. Spawn all components in the graph
    2. Send all initial data values to their respective processes.

  """
  def handle_cast(:start, network) do
    graph_reg_name = network.graph_reg_name
    nodes = Graph.nodes(graph_reg_name)
    # For every component in the graph:
    #   start the process - constructing outport process id's to send to
    Enum.each(nodes, fn (node) ->
      {node_id, label} = Graph.get_node(graph_reg_name, node)
      Component.start(graph_reg_name, node_id, label) end)
    # For every component's inport, see if there is an initial value. If so,
    # send this value to all of processes that have been spawned for this
    # component. We do not use Component.send_ip for this type of message.
    Enum.each(nodes, fn(node) ->
      {node_id, label} = Graph.get_node(graph_reg_name, node)
      inports = label.inports
      for {port, value} <- inports do
        if value != nil do
          number_of_processes = label.metadata[:number_of_processes]
          Enum.each(Range.new(1, number_of_processes), fn(process_no) ->
            process_reg_name = String.to_atom(
                                      Atom.to_string(graph_reg_name)
                                      <> "_"
                                      <> node_id
                                      <> "_#{process_no}")
            send(process_reg_name, {port, value})
          end)
        end
      end
    end)
    new_network = %{network | :status => :started}
    {:noreply, new_network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.stop()
  Stop the currently running graph.
  Unregister and kill all of the node processes.
  """
  def handle_cast(:stop, network) do
    graph_reg_name = network.graph_reg_name
    nodes = Graph.nodes(graph_reg_name)
    Enum.each(nodes, fn(node) ->
      {node_id, label} = Graph.get_node(graph_reg_name, node)
      Component.stop(graph_reg_name, node_id, label) end)
    new_network = %{network | :status => :stopped}
    {:noreply, new_network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.data
  """
  def handle_cast({:data, graph_id, edge_id, src, tgt, subgraph}, network) do
    nodes = Graph.nodes(network.graph_reg_name)
    {:noreply, network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.get_status
  """
  def handle_call(:get_status, _req, network) do
    {:reply, network.status, network}
  end

  @doc """
  Callback implementation for stopping the Network - Note that this is different
  than the stop function.
  """
  def handle_call(:stop_network, _req, network) do
    # Stop the Graph GenServer
    Graph.stop(network.graph_reg_name)
    {:stop, :normal, :ok, network}
  end

end
