defmodule ElixirFBP.Runtime do
  @moduledoc """
  ElixirFBP.Runtime is a GenServer responsible for information related to the
  runtime capabilites of a particular instance of ElixirFBP. In its structure,
  it stores descriptive data, a list of capabilities and a list of components
  that may be used to construct FBP programs.

  Most data is loaded dynamically at GenServer start time but can be
  updated after initialization.

  The GenServer is registered with the name of this module.

  """
  defstruct [
    type: "elixir-fbp",
    version: "0.0.1",
    capabilites: [],
    all_capabilities: [],
    id: "elixir-fbp",
    label: "The runtime for the Elixir language implementation of Flow-Based Programming.",
    graph: nil,
    components: []
  ]

  use GenServer

  ########################################################################
  # The External API

  @doc """
  Start a GenServer instance of an ElixirFBP.Runtime.
  """
  def start_link(parameters \\ %{}) do
    GenServer.start_link(__MODULE__, [parameters], name: __MODULE__)
  end

  @doc """
  Retrieve the value of the the structure part named parameter
  """
  def get_parameter(parameter) do
    GenServer.call(__MODULE__, {:get_parameter, parameter})
  end

  @doc """
  Set the value of the structure part named parameter
  """
  def set_parameter(parameter, value) do
    GenServer.call(__MODULE__, {:set_parameter, parameter, value})
  end

  @doc """
  Stop a GenServer instance of an ElixirFBP.Runtime
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  ########################################################################
  # The GenServer implementations
  def init(parameters) do
    runtime = %ElixirFBP.Runtime{}
    {:ok, runtime}
  end

  @doc """
  Callback implementation for ElixirFBP.Runtime.get_paramter()
  """
  def handle_call({:get_parameter, parameter}, _req, runtime) do
    {:reply, Map.get(runtime, parameter, nil), runtime}
  end

  @doc """
  Callback implementation for ElixirFBP.Runtime.set_paramter()
  """
  def handle_call({:set_parameter, parameter, value}, _req, runtime) do
    new_runtime = Map.put(runtime, parameter, value)
    {:reply, :ok, new_runtime}
  end

  @doc """
  Callback implementation for ElixirFBP.Runtime.stop()
  """
  def handle_call(:stop, _req, runtime) do
    {:stop, :normal, :ok, runtime}
  end

  @doc """
  Terminate is eventually called as this GenServer is stopped.
  """
  def terminate(_reasone, _runtime) do
    :ok
  end

end
