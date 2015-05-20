defmodule ElixirFBPComponentTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Graph
  alias ElixirFBP.Component
  alias ElixirFBP.Network

  # Testing parameters
  @graph_1 "graph_1"
  @graph_2 "graph_2"
  @node_1 "node_1"
  @node_2 "node_2"

  test "Start a component and see if it's alive!" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    process_reg_name = Component.start(fbp_graph_reg_name, @node_1, "Math.Add")
    assert process_reg_name == String.to_atom(@graph_1 <> "_" <> @node_1)
    process_pid = Process.whereis(process_reg_name)
    assert Process.alive?(process_pid)
    # Make sure the process and the graph are unregistered
    Process.unregister(process_reg_name)
    Process.unregister(fbp_graph_reg_name)
  end

  test "Start a component with initial values" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_2)
    {:ok, _fbp_network_pid} =
            Network.start_link(fbp_graph_reg_name)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    Graph.add_initial(fbp_graph_reg_name, 42, @node_1, :augend)
    Graph.add_initial(fbp_graph_reg_name, 42, @node_1, :addend)
    Network.start()
    Network.stop()
    Process.unregister(fbp_graph_reg_name)
  end

end
