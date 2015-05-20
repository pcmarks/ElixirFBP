defmodule ElixirFBPGraphTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Graph

  # Testing parameters
  @graph_1 "graph_1"
  @node_1 "node_1"
  @node_2 "node_2"

  test "Create and persist a graph with default metadata" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert :digraph == elem(fbp_graph.graph, 0)
  end

  test "Clear the FBP graph" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.clear(fbp_graph_reg_name)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert :digraph.no_edges(fbp_graph.graph) == 0
    assert :digraph.no_vertices(fbp_graph.graph) == 0
  end

  test "Clear the FBP graph and change the description" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert nil == fbp_graph.description
    Graph.clear(fbp_graph_reg_name, %{description: "this is a test"})
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert "this is a test" == fbp_graph.description
  end

  test "Add a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert node_id in nodes == true
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    assert label.inports == [{:addend, nil}, {:augend, nil}]
  end

  test "Get the info associated with a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    {_node_id, label} = Graph.get_node(fbp_graph_reg_name, node_id)
    assert label.component == "Math.Add"
  end

  test "Remove a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    result = Graph.remove_node(fbp_graph_reg_name, @node_1)
    assert result == true
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert @node_1 in nodes == false
  end

  test "Add an edge between two nodes" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_edge_id, node1, node2, label} = :digraph.edge(fbp_graph.graph, edge)
    assert node1 == @node_1
    assert node2 == @node_2
    assert label.src_port == :sum
    assert label.tgt_port == :addend
  end

  test "Remove an edge between two nodes" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    # First add an edge
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    # Now remove it
    result = Graph.remove_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    assert result == true
  end

  test "Add an initial value to a node port" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    result = Graph.add_initial(fbp_graph_reg_name, 27, @node_1, :addend)
    assert result == 27
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, @node_1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == 27
  end

  test "Remove an initial value from a node port" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_initial(fbp_graph_reg_name, 27, @node_1, :addend)
    result = Graph.remove_initial(fbp_graph_reg_name, @node_1, :addend)
    assert result == nil
    # Double-check that the value is = nil
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, @node_1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == nil
  end
end
