defmodule ElixirFBPTest do
  use ExUnit.Case

  test "Create and persist a graph with default metadata" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link(33)
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph == elem(fbp_graph.digraph, 0)
  end

  test "Clear the FBP graph" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    ElixirFBP.Graph.clear(33)
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph.no_edges(fbp_graph.digraph) == 0
    assert :digraph.no_vertices(fbp_graph.digraph) == 0
  end

  test "Clear the FBP graph and change the description" do
    {:ok, _} = ElixirFBP.Graph.start_link(33)
    fbp_graph = ElixirFBP.Graph.get
    assert nil == fbp_graph.description
    ElixirFBP.Graph.clear(33, %{description: "this is a test"})
    fbp_graph = ElixirFBP.Graph.get
    assert "this is a test" == fbp_graph.description
  end
end
