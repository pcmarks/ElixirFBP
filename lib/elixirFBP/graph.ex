defmodule ElixirFBP.Graph do
  @moduledoc """
  ElxirFBP.Graph is a GenServer that provides support for the creation and
  maintainance of an FBP Graph.

  An FBP graph contains Nodes connected by Edges. Facilities are provided for
  the creation, deletion, and modification of nodes and edges. Initial Information
  Packets (IIP's) can also be specified.

  Graphs are implemented using Erlang's digraph library.

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the graph sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details.

  TODO: Provide support for Port and Group maintenance.

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
  Starts things off with the creation of the state.
  """
  def start_link(graph_id, parameters \\ %{}) do
    GenServer.start_link(__MODULE__, [graph_id, parameters], name: __MODULE__)
  end

  @doc """
  Retreive the FBP Graph structure - primarily for testing/debugging
  """
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Return the current list of nodes
  """
  def nodes do
    GenServer.call(__MODULE__, :nodes)
  end

  @doc """
  Clear/empty the current FBP Graph. Reset the metadata.
  """
  def clear(id, parameters \\ %{}) do
    GenServer.call(__MODULE__, {:clear, id,
                                parameters[:name],
                                parameters[:library],
                                parameters[:main],
                                parameters[:description]})
  end

  @doc """
  Add a node to the FBP Graph
  """
  def add_node(graph_id, node) do
    GenServer.call(__MODULE__, {:add_node, graph_id, node})
  end

  ########################################################################
  # The GenServer implementation

  @doc """
  Initialize the FBP Graph Structure which becomes the State
  """
  def init([id, parameters]) do
    graph = :digraph.new([:protected])
    fbp_graph = %ElixirFBP.Graph{id: id,
                                 name: parameters[:name],
                                 library: parameters[:library],
                                 main: parameters[:main],
                                 description: parameters[:description],
                                 graph: graph}
    {:ok, fbp_graph}
  end

  @doc """
  Return the FBP Graph structure
  """
  def handle_call(:get, _requester, fbp_graph) do
    {:reply, fbp_graph, fbp_graph}
  end

  @doc """
  Return the current list of nodes.
  """
  def handle_call(:nodes, _requester, fbp_graph) do
    {:reply, :digraph.vertices(fbp_graph.graph), fbp_graph}
  end

  @doc """
  A request to clear the FBP Graph. Clearing is accomplished by
  deleting all the vertices and all the edges.
  """
  def handle_call({:clear, id, name, library, main, description},
                    _requester, fbp_graph) do
    graph = fbp_graph.graph
    vertices = :digraph.vertices(graph)
    edges = :digraph.edges(graph)
    :digraph.del_vertices(graph, vertices)
    :digraph.del_edges(graph, edges)
    new_fbp_graph = %ElixirFBP.Graph{id: id, name: name, library: library,
          main: main, description: description, graph: graph}
    {:reply, nil, new_fbp_graph}
  end

  def handle_call({:add_node, graph_id, node}, _requester, fbp_graph) do
    :digraph.add_vertex(fbp_graph.graph, node)
    {:reply, nil, fbp_graph}
  end
end
