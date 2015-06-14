defmodule ElixirFBP.Graph do
  @moduledoc """
  ElxirFBP.Graph is a GenServer that provides support for the creation and
  maintainance of an FBP Graph.

  An FBP graph contains Nodes connected by Edges. Facilities are provided for
  the creation, deletion, and modification of nodes and edges. Initial Information
  Packets (IIP's) can also be specified.

  Graphs are implemented using Erlang's digraph library.

  The digraph Label associated with a node (digraph vertex) is
  [component, inports, inport_types, outports, outport_types, metadata] where
  component is the string name
  of a component e.g., "Math.Add". inports
  and outports are lists of atomic name, initial value pairs, e.g., {:augend, 2} and
  inport_types and outport_types are lists of atomic name, type, e.g., {:augend, :integer}.

  Initial values can be set using the graph add_initial command.

  The digraph Label associated with an edge is [src.port,, tgt.port, metadata] where src.port
  and tgt.port are atom values for the component's ports.

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the graph sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details.

  TODO: Provide support for Port and Group maintenance.
  TODO: Use secret parameter
  TODO: Handle :digraph errors
  TODO: Metadata needs to be stored somewhere in add_initial()

  """
  defstruct [
    id: "",
    name: "",
    library: nil,
    main: false,
    icon: nil,
    description: "",
    registered_name: nil,
    running: false,
    started: false,
    graph: nil
  ]
  @type t :: %__MODULE__{
                id: String.t,
                name: String.t,
                library: module,
                main: boolean,
                icon: String.t,
                description: String.t,
                registered_name: atom,
                running: boolean,
                started: boolean,
                graph: atom}

  use GenServer

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the state. Register it with the name
  graph_id - converted to an atom.
  """
  def start_link(graph_id, parameters \\ %{}) do
    registered_name = String.to_atom(graph_id)
    {:ok, _pid} = GenServer.start_link(__MODULE__,
                                      [graph_id, registered_name, parameters],
                                      name: registered_name)
    {:ok, registered_name}
  end

  @doc """
  Set the parameters associated with this graph
  """
  def set_parameters(fbp_graph_reg_name, parameters \\ %{}) do
    GenServer.call(fbp_graph_reg_name, {:set_parameters, parameters})
  end

  @doc """
  Start the execution of the components in this graph.
  """
  def start(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :start)
  end

  @doc """
  Stop the execution of the components in this graph.
  This should normally be called via the Network.stop(graph_id) function.
  """
  def stop_graph(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :stop_graph)
  end

  @doc """
  Retreive the FBP Graph structure - primarily used for testing/debugging
  """
  def get(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :get)
  end

  @doc """
  Return the status variables for this graph
  """
  def get_status(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :get_status)
  end

  @doc """
  Return the current list of nodes
  """
  def nodes(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :nodes)
  end

  @doc """
  Return info about a node.
  """
  def get_node(fbp_graph_reg_name, node_id) do
    GenServer.call(fbp_graph_reg_name, {:get_node, node_id})
  end

  @doc """
  Return the current list of edges - primarily used for testing/debugging.
  """
  def edges(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :edges)
  end

  @doc """
  Add a node to the FBP Graph. Note the number of default processes is 1.
  """
  def add_node(fbp_graph_reg_name, node_id, component,
               metadata \\ %{:number_of_processes => 1}) do
    GenServer.call(fbp_graph_reg_name, {:add_node, node_id, component, metadata})
  end

  @doc """
  Remove a node from the FBP Graph
  """
  def remove_node(fbp_graph_reg_name, node_id) do
    GenServer.call(fbp_graph_reg_name, {:remove_node, node_id})
  end

  @doc """
  Add an edge to the FBP Graph
  """
  def add_edge(fbp_graph_reg_name,
                src_node_id, src_port,
                tgt_node_id, tgt_port,
                metadata \\ %{}) do
    GenServer.call(fbp_graph_reg_name,
          {:add_edge, src_node_id, src_port, tgt_node_id, tgt_port, metadata})
  end

  @doc """
  Remove the edge between the two given node/ports in the FBP Graph
  """
  def remove_edge(fbp_graph_reg_name,
                  src_node_id, src_port,
                  tgt_node_id, tgt_port) do
    GenServer.call(fbp_graph_reg_name,
          {:remove_edge, src_node_id, src_port, tgt_node_id, tgt_port})
  end

  @doc """
  Place an initial value at the port of a node in the FBP Graph
  """
  def add_initial(fbp_graph_reg_name, data, node_id, port, metadata \\ %{}) do
    GenServer.call(fbp_graph_reg_name, {:add_initial, data, node_id, port, metadata})
  end

  @doc """
  Remove an initial value at the port of a node in the FBP Graph. It is set to
  the value nil.
  """
  def remove_initial(fbp_graph_reg_name, node_id, port) do
    GenServer.call(fbp_graph_reg_name, {:remove_initial, node_id, port})
  end

  @doc """
  Stop this GenServer
  """
  def stop(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :stop)
  end

  ########################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Graph.clear()
  Create and initialize the FBP Graph Structure which becomes the State
  """
  def init([graph_id, registered_name, parameters]) do
    # The digraph is where all the nodes and edges are stored
    graph = :digraph.new([:protected])
    fbp_graph = %ElixirFBP.Graph{id: graph_id,
                                 name: parameters[:name],
                                 library: parameters[:library],
                                 main: parameters[:main],
                                 icon: parameters[:icon],
                                 description: parameters[:description],
                                 registered_name: registered_name,
                                 graph: graph}
    {:ok, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.set_parameters()
  Set the parameters associated with this registered graph
  """
  def handle_call({:set_parameters, parameters}, _req, fbp_graph) do
    new_fbp_graph = %ElixirFBP.Graph{fbp_graph |
                                    name: parameters[:name],
                                    library: parameters[:library],
                                    main: parameters[:main],
                                    icon: parameters[:icon],
                                    description: parameters[:description]}
    {:reply, :ok, new_fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.start()
  Starting a graph involves the following steps:
    1. Spawn all components in the graph
    2. Send all initial data values to their respective processes.

  """
  def handle_call(:start, _req, fbp_graph) do
    reg_name = fbp_graph.registered_name
    nodes = :digraph.vertices(fbp_graph.graph)
    # For every component in the graph:
    #   start the process - constructing outport process id's to send to
    Enum.each(nodes, fn (node) ->
      {node_id, label} = :digraph.vertex(fbp_graph.graph, node)
    # For every component's inport, see if there is an initial value. If so,
      ElixirFBP.Component.start(reg_name, node_id, label, fbp_graph.graph) end)
    # send this value to all of processes that have been spawned for this
    # component. We do not use Component.send_ip for this type of message.
    Enum.each(nodes, fn(node) ->
      {node_id, label} = :digraph.vertex(fbp_graph.graph, node)
      inports = label.inports
      for {port, value} <- inports do
        if value != nil do
          number_of_processes = label.metadata[:number_of_processes]
          Enum.each(Range.new(1, number_of_processes), fn(process_no) ->
            process_reg_name = String.to_atom(
                                      Atom.to_string(reg_name)
                                      <> "_"
                                      <> node_id
                                      <> "_#{process_no}")
            send(process_reg_name, {port, value})
          end)
        end
      end
    end)
    new_fbp_graph = %ElixirFBP.Graph{fbp_graph | started: true, running: true}
    {:reply, :ok, new_fbp_graph}
  end

  @doc """
  Callback implementation of ElxirFBP.Graph.get()
  Return the FBP Graph structure
  """
  def handle_call(:get, _req, fbp_graph) do
    {:reply, fbp_graph, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.get_status()
  Return the status variables as a tuple.
  """
  def handle_call(:get_status, _req, fbp_graph) do
    {:reply, {fbp_graph.running, fbp_graph.started}, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.nodes()
  Return the current list of nodes.
  """
  def handle_call(:nodes, _req, fbp_graph) do
    {:reply, :digraph.vertices(fbp_graph.graph), fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.get_node()
  Returns {vertex, label}
  """
  def handle_call({:get_node, node_id}, _req, fbp_graph) do
    graph = fbp_graph.graph
    {:reply, :digraph.vertex(graph, node_id), fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.edges()
  Return the current list of edges.
  """
  def handle_call(:edges, _req, fbp_graph) do
    {:reply, :digraph.edges(fbp_graph.graph), fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_node()
  """
  def handle_call({:add_node, node_id, component, metadata}, _req, fbp_graph) do
    component_inports = elem(Code.eval_string(component <> ".inports"), 0)
    component_outports = elem(Code.eval_string(component <> ".outports"), 0)
    # Construct a list of port name, value pairs that will be used to hold
    # initial values.
    inports = Enum.map(component_inports, fn(inport) ->
      {elem(inport,0), nil}
      end)
    outports = Enum.map(component_outports, fn(outport) ->
      {elem(outport,0), nil}
      end)
    label = %{component: component,
              inports: inports, inport_types: component_inports,
              outports: outports, outport_types: component_outports,
              metadata: metadata}
    new_vertex = :digraph.add_vertex(fbp_graph.graph, node_id, label)
    {:reply, new_vertex, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_node()
  """
  def handle_call({:remove_node, node_id}, _req, fbp_graph) do
    result = :digraph.del_vertex(fbp_graph.graph, node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_edge()
  """
  def handle_call({:add_edge,
                    src_node_id, src_port,
                    tgt_node_id, tgt_port,
                    metadata}, _req, fbp_graph) do
    label = %{src_port: src_port, tgt_port: tgt_port, metadata: metadata}
    new_edge = :digraph.add_edge(
                    fbp_graph.graph,
                    src_node_id,
                    tgt_node_id,
                    label)
    {:reply, new_edge, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_edge(graph_reg_name)
  """
  def handle_call({:remove_edge,
                    src_node_id, src_port,
                    tgt_node_id, tgt_port},
                    _req, fbp_graph) do
    result = :digraph.del_path(fbp_graph.graph, src_node_id, tgt_node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_initial(graph_reg_name)
  """
  def handle_call({:add_initial, data, node_id, port, metadata}, _req, fbp_graph) do
    {node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    inports = label.inports
    inport_types = label.inport_types
    initial_value = convert_to_type(inport_types[port], data)
    new_inports = Keyword.put(inports, port, initial_value)
    new_label = %{label | :inports => new_inports}
    :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
    {:reply, initial_value, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_initial(graph_reg_name)
  """
  def handle_call({:remove_initial, node_id, port}, _req, fbp_graph) do
    {node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    inports = label.inports
    new_inports = Keyword.put(inports, port, nil)
    new_label = %{label | :inports => new_inports}
    :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
    {:reply, nil, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.stop(graph_name)
  Stop the execution of a graph.
  Unregister and kill all of the node processes.
  """
  def handle_call(:stop_graph, _req, fbp_graph) do
    reg_name = fbp_graph.registered_name
    nodes = :digraph.vertices(fbp_graph.graph)
    Enum.each(nodes, fn(node) ->
      {node_id, label} = :digraph.vertex(fbp_graph.graph, node)
      ElixirFBP.Component.stop(reg_name, node_id, label) end)
      new_fbp_graph = %ElixirFBP.Graph{fbp_graph | running: false, started: false}
    {:reply, :ok, new_fbp_graph}
  end

  @doc """
  Callback implementation for stopping this GenServer.
  """
  def handle_call(:stop, _req, fbp_graph) do
    # Graph.stop(fbp_graph.registered_name)
    {:stop, :normal, :ok, fbp_graph}
  end

  @doc """
  Callback implementation triggered by asking the GenServer to :stop
  """
  def terminate(reason, fbp_graph) do
    :ok
  end

  defp convert_to_type(:integer, data) when is_bitstring(data) do
    String.to_integer(data)
  end
  defp convert_to_type(:integer, data) when is_integer(data) do
    data
  end
  defp convert_to_type(:string, data) when is_bitstring(data) do
    data
  end
  defp convert_to_type(:pid, data) when is_pid(data) do
    data
  end
end
