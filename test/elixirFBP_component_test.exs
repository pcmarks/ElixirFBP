defmodule ElixirFBPComponentTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Graph
  alias ElixirFBP.Component
  alias ElixirFBP.Network

  # Testing parameters
  @graph_1 "graph_c1"
  @graph_2 "graph_c2"
  @node_1 "node_1"
  @node_2 "node_2"

  test "Start a component and see if it's alive!" do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    {_node_id, label} = Graph.get_node(fbp_graph_reg_name, @node_1)
    Graph.get(fbp_graph_reg_name)
    Component.stop(fbp_graph_reg_name, @node_1, label)
    Network.stop(@graph_1)
    Network.stop
  end

  test "Start a component with initial values" do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_2)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    Graph.add_initial(fbp_graph_reg_name, 42, @node_1, :augend)
    Graph.add_initial(fbp_graph_reg_name, 42, @node_1, :addend)
    Network.stop(@graph_2)
    Network.stop
  end

end
