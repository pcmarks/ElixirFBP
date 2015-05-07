defmodule ElixirFBPTest do
  use ExUnit.Case

  test "Create and persist a graph" do
    graph = :digraph.new()
#    fbp_graph = %ElixirFBP.Graph
    {:ok, fbp_graph_process} = ElixirFBP.Graph.start_link(graph)
  end
end
