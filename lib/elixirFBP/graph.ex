defmodule ElixirFBP.Graph do
  @moduledoc """
  ElxirFBP.Graph is a GenServer that provides support for the creation and
  maintainance of an FBP Graph.

  An FBP graph contains Nodes connected by Edges. Facilities are provided for
  the creation, deletion, and modification of nodes and edges. Initial Information
  Packets (IIP's) can also be specified.

  Graphs are implemented using Erlang's digraph library.

  The digraph Label associated with a node (digraph vertex) is
  [component, inports, outports, metadata] where component is the string name
  of a component - tentatively: "Module", e.g., "Math.Add". inports
  and outports are lists of atomic name, initial value pairs, e.g., {:augend, 2}.
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
    id: nil,
    name: "",
    library: nil,
    main: false,
    description: "",
    graph: nil
  ]
  @type t :: %ElixirFBP.Graph{id: String.t, name: String.t}
  use GenServer

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the state. Register it with name
  graph_id - converted to an atom.
  """
  def start_link(graph_id, parameters \\ %{}) do
    fbp_graph_process_name = String.to_atom(graph_id)
    GenServer.start_link(__MODULE__, [fbp_graph_process_name, parameters],
                         name: fbp_graph_process_name)
  end

  @doc """
  Retreive the FBP Graph structure - primarily used for testing/debugging
  """
  def get(graph_id) do
    GenServer.call(graph_id, :get)
  end

  @doc """
  Return the current list of nodes
  """
  def nodes(graph_id) do
    GenServer.call(graph_id, :nodes)
  end

  @doc """
  Return info about a node.
  """
  def get_node(graph_id, node_id) do
    GenServer.call(graph_id, {:get_node, node_id})
  end

  @doc """
  Return the current list of edges - primarily used for testing/debugging.
  """
  def edges(graph_id) do
    GenServer.call(graph_id, :edges)
  end

  @doc """
  Clear/empty the current FBP Graph. Reset the metadata.
  """
  def clear(graph_id, parameters \\ %{}) do
    GenServer.call(graph_id, {:clear,
                                parameters[:name],
                                parameters[:library],
                                parameters[:main],
                                parameters[:description]})
  end

  @doc """
  Add a node to the FBP Graph
  """
  def add_node(graph_id, node_id, component, metadata \\ %{}) do
    GenServer.call(graph_id, {:add_node, node_id, component, metadata})
  end

  @doc """
  Remove a node from the FBP Graph
  """
  def remove_node(graph_id, node_id) do
    GenServer.call(graph_id, {:remove_node, node_id})
  end

  @doc """
  Add an edge to the FBP Graph
  """
  def add_edge(graph_id, src, tgt, metadata \\ %{}) do
    GenServer.call(graph_id, {:add_edge, src, tgt, metadata})
  end

  @doc """
  Remove the edge between the two given node/ports in the FBP Graph
  """
  def remove_edge(graph_id, src, tgt) do
    GenServer.call(graph_id, {:remove_edge, src, tgt})
  end

  @doc """
  Place an initial value at the port of a node in the FBP Graph
  """
  def add_initial(graph_id, src, tgt, metadata \\ %{}) do
    GenServer.call(graph_id, {:add_initial, src, tgt, metadata})
  end

  @doc """
  Remove an initial value at the port of a node in the FBP Graph. It is set to
  the value nil.
  """
  def remove_initial(graph_id, tgt) do
    GenServer.call(graph_id, {:remove_initial, tgt})
  end

  ########################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Graph.start_link()
  Initialize the FBP Graph Structure which becomes the State
  """
  def init([fbp_graph_process_name, parameters]) do
    graph = :digraph.new([:protected])
    fbp_graph = %ElixirFBP.Graph{id: fbp_graph_process_name,
                                 name: parameters[:name],
                                 library: parameters[:library],
                                 main: parameters[:main],
                                 description: parameters[:description],
                                 graph: graph}
    {:ok, fbp_graph}
  end

  @doc """
  Callback implementation of ElxirFBP.get()
  Return the FBP Graph structure
  """
  def handle_call(:get, _req, fbp_graph) do
    {:reply, fbp_graph, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.nodes()
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
  Callback implementation of ElixirFBP.edges()
  Return the current list of edges.
  """
  def handle_call(:edges, _req, fbp_graph) do
    {:reply, :digraph.edges(fbp_graph.graph), fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.clear()
  A request to clear the FBP Graph. Clearing is accomplished by
  deleting all the vertices and all the edges.
  """
  def handle_call({:clear, name, library, main, description},
                    _req, fbp_graph) do
    graph = fbp_graph.graph
    graph_id = fbp_graph.id
    vertices = :digraph.vertices(graph)
    edges = :digraph.edges(graph)
    :digraph.del_vertices(graph, vertices)
    :digraph.del_edges(graph, edges)
    new_fbp_graph = %ElixirFBP.Graph{id: graph_id, name: name, library: library,
          main: main, description: description, graph: graph}
    {:reply, new_fbp_graph, new_fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.add_node()
  """
  def handle_call({:add_node, node_id, component, metadata}, _req, fbp_graph) do
    inports = elem(Code.eval_string(component <> ".inports"), 0)
    outports = elem(Code.eval_string(component <> ".outports"), 0)
    label = %{component: component, inports: inports, outports: outports, metadata: metadata}
    new_vertex = :digraph.add_vertex(fbp_graph.graph, node_id, label)
    {:reply, new_vertex, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.remove_node()
  """
  def handle_call({:remove_node, node_id}, _req, fbp_graph) do
    result = :digraph.del_vertex(fbp_graph.graph, node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.add_edge()
  """
  def handle_call({:add_edge, src, tgt, metadata}, _req, fbp_graph) do
    label = %{src_port: src.port, tgt_port: tgt.port, metadata: metadata}
    new_edge = :digraph.add_edge(
                    fbp_graph.graph,
                    src.node_id,
                    tgt.node_id,
                    label)
    {:reply, new_edge, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.remove_edge()
  """
  def handle_call({:remove_edge, src, tgt}, _req, fbp_graph) do
    result = :digraph.del_path(fbp_graph.graph, src.node_id, tgt.node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.add_initial()
  """
  def handle_call({:add_initial, src, tgt, metadata}, _req, fbp_graph) do
    src_data = src.data
    node_id = tgt.node_id
    port = tgt.port
    {node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    inports = label.inports
    new_inports = Keyword.put(inports, port, src_data)
    new_label = %{label | :inports => new_inports}
    :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
    {:reply, src_data, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.remove_initial()
  """
  def handle_call({:remove_initial, tgt}, _req, fbp_graph) do
    node_id = tgt.node_id
    port = tgt.port
    {node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    inports = label.inports
    new_inports = Keyword.put(inports, port, nil)
    new_label = %{label | :inports => new_inports}
    :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
    {:reply, nil, fbp_graph}
  end
end
