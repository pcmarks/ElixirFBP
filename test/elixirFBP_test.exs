defmodule ElixirFBPTest do
  use ExUnit.Case

  test "Create and persist a graph with default metadata" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph == elem(fbp_graph.digraph, 0)
  end

  test "Clear the FBP graph" do
    {:ok, _} = ElixirFBP.Graph.start_link
    ElixirFBP.Graph.clear
    fbp_graph = ElixirFBP.Graph.get
    assert :digraph.no_edges(fbp_graph.digraph) == 0
    assert :digraph.no_vertices(fbp_graph.digraph) == 0
  end

end
