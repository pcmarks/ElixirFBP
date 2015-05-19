defmodule ElixirFBP.Component do
  @moduledoc """
  Component is used to start an FBP component. It takes the component's name -
  an Elixir module name - and spawns a process. It is assumed that the component
  module supports a loop function which will be called when the component is
  spawned.

  Component is also used to send data to a specific port on a specific node. The
  node has already been spawned and is identified my the atom representation of
  its node name.

  """
  @doc """
  Spawn a process, identified by its component (module) name and with a process
  name of the atom value of graph_id <> "_" <> node_id. This function can figure
  out a node's inports and outports by accessing the respective function in the
  component module definition, e.g. Math.Add.inports
  Return the process name for the spawned process
  """
  def start(graph_reg_name, node_id, component) do
#    IO.puts("Component.start(#{inspect graph_reg_name},#{inspect node_id},#{inspect component})")
    # Retrieve the list of inports and outports for this type of component
    {inports, _} = Code.eval_string(component <> ".inports")
    {_outports, _} = Code.eval_string(component <> ".outports")
    # There should be as many nil inport values as different inports
    inport_args = List.duplicate(nil, length(inports))
    # The outport values consists of the Elixir process name of the node it is
    # connected to along with its port name. Note that we have to prepend
    # the component name with the string "Elixir."
    outport_args = prepare_outport_args(graph_reg_name, node_id)
    process_reg_name = String.to_atom(Atom.to_string(graph_reg_name) <> "_" <> node_id)
    module = Module.concat("Elixir", component)
    # We can spawn the component process now, asking it to execute its loop function.
    process_pid = spawn(module, :loop, inport_args ++ outport_args)
    Process.register(process_pid, process_reg_name)
    process_reg_name
  end

  @doc """
  Stop a component. This means find the process node's pid and unregister it.
  """
  def stop(graph_reg_name, node_id) do
    process_name = String.to_atom(Atom.to_string(graph_reg_name) <> "_" <> node_id)
    Process.unregister(process_name)
  end

  @doc """
  Assemble and send an IP to an inport of a running process.
  """
  def send_ip(target, value) do
    send(target.process_reg_name, {target.inport, value})
  end

  @doc """
  A private function that can assemble the process id and port name that a
  component is connected to. The connection is between an outport and an inport.
  """
  defp prepare_outport_args(graph_reg_name, node_id) do
    fbp_graph = ElixirFBP.Graph.get(graph_reg_name)
    out_edges = :digraph.out_edges(fbp_graph.graph, node_id)
    process_reg_name = String.to_atom(Atom.to_string(graph_reg_name) <> "_" <> node_id)
    Enum.map(out_edges, fn(out_edge) ->
      {_, _src_node, _tgt_node, label} = :digraph.edge(fbp_graph.graph, out_edge)
      %{process_reg_name: process_reg_name, inport: label.tgt_port}
    end)
  end

end
