defmodule ElixirFBP.Component do
  @moduledoc """
  Component is used to start an FBP component. It takes the component's name -
  an Elixir module name - and spawns a process. It is assumed that the component
  module supports a loop function which will be called when the component is
  spawned.

  Component is also used to send data to a specific port on a specific node. The
  node has already been spawned and is identified by the atom representation of
  its node name.

  """
  @doc """
  Start the execution of a component in its own process(es).
  This function can figure out a component's inports and outports by accessing
  the respective function in the component module definition, e.g.
  Math.Add.inports. The argument label refers to the label value associated with
  the Erlang :digraph vertex.
  Spawn as many process as are specified in the metadata :number_of_processes value (the
  default value is one), each identified with a process name of the atom value
  of graph_id <> "_" <> node_id <> process_number, where process_number
  goes from 1 to number_of_processes.
  Return {:ok, process name, number} or {:error, reason} where process name
  (string) is the spawned process root name and number is the number of processes
  started.
  """
  def start(graph_reg_name, node_id, label, fbp_graph) do
    # IO.puts("Component.start(#{inspect graph_reg_name},#{inspect node_id},#{inspect component})")
    # Retrieve the list of inports and outports for this component
    {inports, _} = Code.eval_string(label.component <> ".inports")
    {outports, _} = Code.eval_string(label.component <> ".outports")

    # Spawning a process requires a module name - Note that we have to prepend
    # the component name with "Elxir" and a list of argument values - to the loop
    # function for a component. The in port arguments are nil but the out port
    # arguments need to be set up with the name of the component process that
    # it is connected to.
    #inport_args = List.duplicate(nil, length(inports))
    inport_args = inports |> Enum.map(fn({k, _v}) -> {k, nil} end) |> Enum.into(%{})
    outport_args = prepare_outport_args(graph_reg_name, node_id, fbp_graph) |>
                    Enum.into(%{})
    process_reg_name = Atom.to_string(graph_reg_name) <> "_" <> node_id
    module = Module.concat("Elixir", label.component)
    number_of_processes = label.metadata[:number_of_processes]
    # We can spawn all of the component processes now,
    # asking each component process to execute its loop function.
    Enum.each(Range.new(1, number_of_processes), fn(process_no) ->
      process_pid = spawn(module, :loop, [inport_args, outport_args])
      process_reg_name_atom = String.to_atom("#{process_reg_name}_#{process_no}")
      Process.register(process_pid, process_reg_name_atom)
    end)
    {process_reg_name, number_of_processes}
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

  @doc """
  Assemble and send an IP to an in port of a running process. If there are
  multiple processes for this component, send it to the "next" process.
  Return an updated target with a new next process number.
  """
  def send_ip(target, value) do
    # IO.puts("\nComponent.send_ip(#{inspect target}, #{inspect value})")
    no_of_processes = Map.get(target, :number_of_processes, 1)
    next_process = Map.get(target, :next_process, 0)
    processes = Map.get(target, :process_reg_names)
    send(elem(processes, next_process), {target.inport, value})
    if no_of_processes == 1 do
      next_process_no = 0
    else
      next_process_no = next_process + 1
      if next_process_no >= no_of_processes do
        next_process_no = 0
      end
    end
    %{target | :next_process => next_process_no}
  end

  @doc """
  A private function that can assemble the process id and port name that a
  component is connected to. The connection is between an out port and an in port.
  If there is no connection (no edges) on this out port an error is returned.
  """
  defp prepare_outport_args(graph_reg_name, node_id, graph) do
    # fbp_graph = ElixirFBP.Graph.get(graph_reg_name)
    out_edges = :digraph.out_edges(graph, node_id)
    Enum.map(out_edges, fn(out_edge) ->
      {_, _src_node, tgt_node, edge_label} = :digraph.edge(graph, out_edge)
      {tgt_node, node_label} = :digraph.vertex(graph, tgt_node)
      number_of_processes = node_label.metadata[:number_of_processes]
      process_reg_names =
        Enum.map(Range.new(1, number_of_processes), fn(i) ->
          String.to_atom(
              Atom.to_string(graph_reg_name) <> "_" <> tgt_node <> "_#{i}")
        end)
      {edge_label.src_port, %{process_reg_names: List.to_tuple(process_reg_names),
        number_of_processes: number_of_processes,
        next_process: 0,
        inport: edge_label.tgt_port}}
    end)
  end

end
