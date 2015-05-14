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

  """
  defstruct [
    graph_id: nil,
    status: :stopped
  ]

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the state.
  """
  def start_link(graph_id) do
    GenServer.start_link(__MODULE__, graph_id, name: __MODULE__)
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

  ########################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Network.start_link()
  Initialize the state with an FBP graph.
  """
  def init(graph_id) do
    {:ok, %ElixirFBP.Network{graph_id: graph_id}}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.start()
  Starting a network involves the following steps:
    1. Spawn (start_link) all components in the graph
    2. Send all initial data values to their respective processes.

  """
  def handle_cast(:start, network) do
    new_network = %{network | :status => :started}
    {:noreply, new_network}
  end

  @doc """
  Callback implementation for ElixirFBP.Network.stop()
  Stop the currently running graph.
  """
  def handle_cast(:stop, network) do
    new_network = %{network | :status => :stopped}
    {:noreply, new_network}
  end
  
  @doc """
  Callback implementation for ElixirFBP.Network.get_status
  """
  def handle_call(:get_status, _req, network) do
    {:reply, network.status, network}
  end
end
