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
  Return a tuple with a key of the node_id and a value of a
  list of pids corresponding to the spawned component processes.
  """
  def start(graph_reg_name, node_id, label, fbp_graph) do
    # IO.puts("Component.start(#{inspect graph_reg_name},#{inspect node_id},#{inspect component})")
    # Retrieve the list of inports and outports for this component
    {inports, _} = Code.eval_string(label.component <> ".inports")
    {outports, _} = Code.eval_string(label.component <> ".outports")

    # Spawning a process requires a module name - Note that we have to prepend
    # the component name with "Elxir" and a list of argument values - to the loop
    # function for a component.
    inport_args = inports |> Enum.map(fn({k, _v}) -> {k, nil} end) |> Enum.into(%{})
    outport_args =  outports |> Enum.map(fn({k, _v}) -> {k, nil} end) |> Enum.into(%{})
    module = Module.concat("Elixir", label.component)
    number_of_processes = label.metadata[:number_of_processes]
    # We can spawn all of the component processes now,
    # asking each component process to execute its loop function.
    {node_id, Enum.map(1..number_of_processes, fn(_) ->
      spawn(module, :loop, [inport_args, outport_args])
    end)}
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
