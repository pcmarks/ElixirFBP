defmodule ElixirFBP.Runtime do
  @moduledoc """
  ElixirFBP.Runtime is a GenServer responsible for information related to the
  runtime capabilites of a particular instance of ElixirFBP. In its structure,
  it stores descriptive data, a list of capabilities and a list of components
  that may be used to construct FBP programs.

  The client that is currently connected to this runtime is stored in the state.
  It is expected that this is a pid to which messages can be sent and that are
  understood by that particular client. For example, if the client-runtime
  connection is via Websockets then this pid is a Websocket handler.

  The list of components that are available to users of this runtime are stored
  in the state. This list will be used as a response to a client request for a
  list of components.

  Most data are loaded dynamically at GenServer start time but can be
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
    components: [],
    client: nil
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
  Register the process that represents the client that this runtime will
  communicate with.
  """
  def register_client(client) do
    GenServer.call(__MODULE__, {:set_parameter, :client, client})
  end

  @doc """
  Send the currently connected client a message. The process representing the
  client should know how to parse this message.
  """
  def send_client_message(message) do
    GenServer.call(__MODULE__, {:send_client_message, message})
  end

  @doc """
  Send the currently connected client an error message. The process representing the
  client should know how to parse this message.
  """
  def send_client_error(message) do
    GenServer.call(__MODULE__, {:send_client_error, message})
  end

  @doc """
  Stop a GenServer instance of an ElixirFBP.Runtime
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  ########################################################################
  # The GenServer implementations
  @doc """
  Callback implementation for ElixirFBP.Runtime.start_link
  Start up a Network and initialize the Runtime state.
  """
  def init(_parameters) do
    ElixirFBP.Network.start_link
    #################
    # The following components are hardwired.
    # ToDo: Subsequent releases will locate all components
    #################
    modules = [Math.Add, Core.Output]
    # modules = [Streamtools.Filter, Streamtools.GetHTTPJSON,
    #   Streamtools.Map, Streamtools.Ticker, Streamtools.Unpack]
    components = ElixirFBP.ComponentLoader.get_components(modules)
    runtime = %ElixirFBP.Runtime{:components => components}
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
  Callback implementation for ElixirFBP.Runtime.send_client_message()
  """
  def handle_call({:send_client_message, message}, _req, runtime) do
    case Map.get(runtime, :client) do
      client when not is_nil(client) ->
        send client, {:output, message}
    end
    {:reply, :ok, runtime}
  end

  @doc """
  Callback implementation for ElixirFBP.Runtime.send_client_error()
  """
  def handle_call({:send_client_error, message}, _req, runtime) do
    case Map.get(runtime, :client) do
      client when not is_nil(client) ->
        send client, {:error, message}
    end
    {:reply, :ok, runtime}
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
