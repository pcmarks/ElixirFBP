defmodule ElixirFBPNetworkTest do
  use ExUnit.Case, async: false
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "graph_1"
  @node_1       "node_1"
  @node_2       "node_2"

  test "Start and stop the FBP Network" do
    Network.start_link
    assert :ok == Network.stop
  end

  test "Create an ElixirFBP Graph" do
    Network.start_link
    {:ok, _fbp_graph = Network.clear(@graph_1)}
    status = Network.get_status(@graph_1)
    assert status == {false, false}
    # Make sure the graph and network are stopped
    Network.stop(@graph_1)
    assert :ok == Network.stop
  end

  test "Create and start an ElxirFBP Graph" do
    Network.start_link
    {:ok, fbp_graph} = Network.clear(@graph_1)
    Graph.add_node(fbp_graph, @node_1, "Math.Add")
    Graph.add_node(fbp_graph, @node_2, "Core.Output")
    _edge = Graph.add_edge(
                  fbp_graph,
                  @node_1, :sum,
                  @node_2, :in_port)

    Graph.add_initial(fbp_graph, 42, @node_1, :addend)
    Graph.add_initial(fbp_graph, 24, @node_1, :augend)
    Network.start(@graph_1)
    status = Network.get_status(@graph_1)
    assert status == {true, true}
    # Sleep a little while to make sure the computation is finished
    :timer.sleep(10)
    # # Make sure the graph and network are stopped
    Network.stop(@graph_1)
    # # kill the network process
    assert :ok == Network.stop
  end

end
