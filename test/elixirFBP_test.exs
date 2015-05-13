defmodule ElixirFBPTest do
  use ExUnit.Case, async: false

  test "Create and persist a graph with default metadata" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link(33)
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph == elem(fbp_graph.graph, 0)
  end

  test "Clear the FBP graph" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.clear(33)
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph.no_edges(fbp_graph.graph) == 0
    assert :digraph.no_vertices(fbp_graph.graph) == 0
  end

  test "Clear the FBP graph and change the description" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    fbp_graph = ElixirFBP.Graph.get
    assert nil == fbp_graph.description
    ElixirFBP.Graph.clear(33, %{description: "this is a test"})
    fbp_graph = ElixirFBP.Graph.get
    assert "this is a test" == fbp_graph.description
  end

  test "Add a node" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    nodes = ElixirFBP.Graph.nodes
    assert :node1 in nodes == true
    fbp_graph = ElixirFBP.Graph.get
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, :node1)
    assert label.inports == [{:addend, nil}, {:augend, nil}]
  end

  test "Remove a node" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    result = ElixirFBP.Graph.remove_node(33, :node1)
    assert result == true
    nodes = ElixirFBP.Graph.nodes
    assert :node1 in nodes == false
  end

  test "Add an edge between two nodes" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    ElixirFBP.Graph.add_node(33, :node2, "Math.Add")
    edge = ElixirFBP.Graph.add_edge(
                  33,
                  %{node_id: :node1, port: :sum},
                  %{node_id: :node2, port: :addend})
    fbp_graph = ElixirFBP.Graph.get
    {_edge_id, node1, node2, label} = :digraph.edge(fbp_graph.graph, edge)
    assert node1 == :node1
    assert node2 == :node2
    assert label.src_port == :sum
    assert label.tgt_port == :addend
  end

  test "Remove an edge between two nodes" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    # First add an edge
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    ElixirFBP.Graph.add_node(33, :node2, "Math.Add")
    edge = ElixirFBP.Graph.add_edge(
                  33,
                  %{node_id: :node1, port: :sum},
                  %{node_id: :node2, port: :addend})
    # Now remove it
    result = ElixirFBP.Graph.remove_edge(
                  33,
                  %{node_id: :node1, port: :sum},
                  %{node_id: :node2, port: :addend})
    assert result == true
  end

  test "Add an initial value to a node port" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    result = ElixirFBP.Graph.add_initial(33, %{data: 27}, %{node_id: :node1, port: :addend})
    assert result == 27
    fbp_graph = ElixirFBP.Graph.get
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, :node1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == 27
  end

  test "Remove an initial value from a node port" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.add_node(33, :node1, "Math.Add")
    result = ElixirFBP.Graph.remove_initial(33, %{node_id: :node1, port: :addend})
    assert result == nil
    # Double-check that the value is = nil
    fbp_graph = ElixirFBP.Graph.get
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, :node1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == nil
  end
end
