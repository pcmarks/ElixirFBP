defmodule ElixirFBP.Network do
  @moduledoc """
  ElxirFBP.Network is a GenServer that provides support for starting and stopping a
  FBP network, and finding out about its state. The network keeps
  a dictionary of graphs ids, each of which points to an ElixirFBP.Graph structure.
  Graphs are also implemented as GenServers

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the network sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details. There is one exception: the clear graph command is implemented here.

  There is a function - remove_graph - that is not part of the Network Protocol.

  This module is registered with its module name.

  TODO: Finish implementation of data function

  """
  defstruct [
    graph_reg_names: HashDict.new, # graph id => registered name
    debug: false
  ]

  #This module's behaviour
  use GenServer

  alias ElixirFBP.Graph

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the empty state.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Clear adds a new graph in the network. This command is part of the Graph protocol
  but here it is implemented as a network command because it seems like a better fit.
  """
  def clear(graph_id, parameters \\ %{}) do
    GenServer.call(__MODULE__, {:clear, graph_id, parameters})
  end

  @doc """
  Retrieve the registered graph name if it exists. A call to clear will have created
  and registered it.
  """
  def get_graph(graph_id) do
    GenServer.call(__MODULE__, {:get_graph, graph_id})
  end

  @doc """
  Set the network debug switch on or off
  """
  def set_debug(value) do
    GenServer.call(__MODULE__, {:set_debug, value})
  end

  @doc """
  Remove a graph from this network.
  """
  def remove_graph(graph_id) do
    GenServer.call(__MODULE__, {:remove_graph, graph_id})
  end

  @doc """
  Start execution of a graph, optionally specifing whether it is to
  run in either :pull or :push (default) mode.
  """
  def start(graph_id, run_mode \\ :push) do
    GenServer.call(__MODULE__, {:start, graph_id, run_mode})
  end

  @doc """
  Stop the execution of the graph
  """
  def stop(graph_id) do
    GenServer.call(__MODULE__, {:stop, graph_id})
  end

  @doc """
  Get the current status of a graph
  """
  def get_status(graph_id, secret \\ nil) do
    GenServer.call(__MODULE__, {:get_status, graph_id, secret})
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
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  ########################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Network.start_link()
  Initialize the state - no graphs. There are no initialization args.
  """
  def init(_args) do
    {:ok, %ElixirFBP.Network{}}
  end

  @doc """
  Clear (initialize) a graph in this network. If the graph's GenServer has
  not been started and registered, do so.
  """
  def handle_call({:clear, graph_id, parameters}, _req, network) do
    HashDict.get(network.graph_reg_names, graph_id)
    |> handle_call_clear(graph_id, parameters, network)
  end

  @doc """
  Callback implementation of ElxirFBP.Network.get_graph()
  """
  def handle_call({:get_graph, graph_id}, _req, network) do
    registered_name = HashDict.get(network.graph_reg_names, graph_id)
    {:reply, {:ok, registered_name}, network}
  end

  @doc """
  Callback implementation of ElixirFBP.Network.set_debug()
  """
  def handle_call({:set_debug, value}, _req, network) when is_boolean(value) do
    {:reply, :ok, %ElixirFBP.Network{network | debug: value}}
  end

  @doc """
  Remove a graph (%ElixirFBP.Graph structure) from the networks dictionary of graphs.
  """
  def handle_call({:remove_graph, graph_id}, _req, network) do
    new_graph_reg_names = HashDict.delete(network.graph_reg_names, graph_id)
    {:reply, :ok,
           %ElixirFBP.Network{network | graph_reg_names: new_graph_reg_names}}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.start()
  """
  def handle_call({:start, graph_id, run_mode}, _req, network) do
    reg_name = HashDict.get(network.graph_reg_names, graph_id)
    if ! reg_name do
      {:reply, {:error, "Graph does not exist"}, network}
    else
      case Graph.start(reg_name, run_mode) do
        {:ok} ->
          {:reply, :ok, network}
        error ->
          {:reply, error, network}
      end
    end
  end

  @doc """
  Callback implementation for ElixirFBP.Network.get_status
  """
  def handle_call({:get_status, graph_id, _secret}, _req, network) do
    reg_name = HashDict.get(network.graph_reg_names, graph_id)
    status = Graph.get_status(reg_name)
    {:reply, status, network}
  end

  @doc """
  Callback implementation for stopping the Network - Note that this is different
  than the stop function.
  """
  def handle_call(:stop, _req, network) do
    {:stop, :normal, :ok, network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.stop()
  Stop the execution of a graph identified by its id (string).
  """
  def handle_call({:stop, graph_id}, _req, network) do
    reg_name = HashDict.get(network.graph_reg_names, graph_id)
    Graph.stop_graph(reg_name)
    {:reply, :ok, network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.data
  """
  def handle_cast({:data, _graph_id, _edge_id, _src, _tgt, _subgraph}, network) do
    {:noreply, network}
  end

  @doc """
  Callback implmentation for having asked the GenServer to stop processing
  """
  def terminate(_reason, network) do
    # Stop the Graph GenServers
    Enum.each(HashDict.values(network.graph_reg_names), fn(reg_name) ->
      Graph.stop(reg_name)
    end)
    :ok
  end

  defp handle_call_clear(nil, graph_id, parameters, network) do
    {:ok, registered_name} = Graph.start_link(graph_id, parameters)
    new_graph_reg_names =
      HashDict.put(network.graph_reg_names, graph_id, registered_name)
    {:reply, {:ok, registered_name},
           %ElixirFBP.Network{network | graph_reg_names: new_graph_reg_names}}
  end

  defp handle_call_clear(registered_name, _graph_id, parameters, network) do
    Graph.set_parameters(registered_name, parameters)
    {:reply, {:ok, registered_name}, network}
  end

end
