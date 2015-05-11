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
    ElixirFBP.Graph.add_node(33, :node2, "Math.Subtract")
    edge = ElixirFBP.Graph.add_edge(33, %{node_id: :node1}, %{node_id: :node2})
    fbp_graph = ElixirFBP.Graph.get
    edge1 = :digraph.edge(fbp_graph.graph, edge)
    assert elem(edge1, 1) == :node1
    assert elem(edge1, 2) == :node2
  end

end
