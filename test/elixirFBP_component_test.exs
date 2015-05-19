defmodule ElixirFBPComponentTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Graph
  alias ElixirFBP.Component

  # Testing parameters
  @graph_1 "graph_1"
  @graph_1_name String.to_atom(@graph_1)
  @node_1 "node_1"
  @node_2 "node_2"

  test "Start a component and see if it's alive!" do
    {:ok, _fbp_graph_pid} = Graph.start_link(@graph_1)
    Graph.add_node(@graph_1_name, @node_1, "Math.Add")
    Graph.add_node(@graph_1_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  @graph_1_name,
                  %{node_id: @node_1, port: :sum},
                  %{node_id: @node_2, port: :addend})
    process_name = Component.start(@graph_1_name, @node_1, "Math.Add")
    assert process_name == String.to_atom(@graph_1 <> "_" <> @node_1)
    process_pid = Process.whereis(process_name)
    assert Process.alive?(process_pid)
    # Make sure the process is unregistered
    Process.unregister(process_name)
  end
end
