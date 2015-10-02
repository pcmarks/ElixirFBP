defmodule ElixirFBP.Component do
  @moduledoc """
  Component is used to start an FBP component. It takes the component's name -
  an Elixir module name - and spawns a process. It is assumed that the component
  module supports a loop function which will be called once the component is
  spawned.
  """
  @doc """
  Start the execution of a component in its own process(es). Spawn as many
  processes as are specified in the no_of_processes value (the default value is one).

  inports is a list of {port, value} tuples where value is an initial value or
  a Subscription pid. outports is a list of {port, pid} tuples where the pid is
  a Subscription.

  inports and outports are used to create the initial arguments sent to a
  Component's loop function. They are also used to create lists of component
  pids that must be sent to any Subscriptions that a component's in or out ports
  are connected to.
  """
  def start(component, node_id, inports, outports, no_of_processes \\ 1) do
    # IO.puts("inports: #{inspect inports}")
    # IO.puts("outports: #{inspect outports}")
    # Remove pids as inport values for the spawning of the component process.
    # After the component is spawned, these pids will be used to update the
    # Subscriptions associated with the inports.
    inps = Enum.map(inports, fn
      {port, pid} when is_pid(pid) ->
        {port, nil}
      {port, value} ->
        {port, value}
    end) |> Enum.into(%{})
    outports = Enum.map(outports, fn({port, subscription} = outport) ->
      outport
    end) |> Enum.into(%{})
    module = Module.concat("Elixir", component)
    component_pids = Enum.map(1 .. no_of_processes, fn(_) ->
      spawn(module, :loop, [inps, outports])
    end)
    Enum.each(outports, fn({port, subscription}) ->
      send(subscription, {:publisher_pids, component_pids})
    end)
    Enum.each(inports, fn
      {port, subscription} when is_pid(subscription) ->
        send(subscription, {:subscriber_pids, List.to_tuple(component_pids)})
      {port, initial_value} ->
    end)
  end

  @doc """
  Stop a component. This means find the pid of all of the component's processes,
  unregister it and force an exit.
  """
  def stop(graph_reg_name, node_id, label) do
    number_of_processes = label.metadata[:number_of_processes]
    process_name = Atom.to_string(graph_reg_name) <> "_" <> node_id
    Enum.each(Range.new(1, number_of_processes), fn(process_no) ->
      process_name_atom = String.to_atom(process_name <> "_#{process_no}")
      pid = Process.whereis(process_name_atom)
      if pid != nil do
        Process.unregister(process_name_atom)
        Process.exit(pid, :kill)      # Not really a normal exit??
      end
    end)
  end

end
