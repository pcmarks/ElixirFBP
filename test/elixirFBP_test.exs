defmodule ElixirFBPTest do
  use ExUnit.Case

  test "Create and persist a graph with default metadata" do
    {:ok, fbp_graph_process} = ElixirFBP.Graph.start_link
    digraph = ElixirFBP.Graph.get_graph
    assert :digraph == elem(digraph, 0)
  end

  test "Clear the FBP graph" do
    {:ok, _} = ElixirFBP.Graph.start_link
    ElixirFBP.Graph.clear
    graph = ElixirFBP.Graph.get_graph
    assert :digraph.no_edges(graph.digraph) == 0
    assert :digraph.no_vertices(graph.digraph) == 0
  end

end
