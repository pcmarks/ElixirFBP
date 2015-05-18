defmodule ElixirFBPNetworkTest do
  use ExUnit.Case, async: false
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1  "graph_1"
  @node_1   "node_1"
  @node_2   "node_2"

  test "Create an ElixirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    {:ok, _network_graph_process} =
            Network.start_link(@graph_1)
    status = Network.get_status()
    assert status == :stopped
  end

  test "Start an ElxirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_process, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_process, @node_2, "Core.Output")
    edge = Graph.add_edge(
                  fbp_graph_process,
                  %{node_id: @node_1, port: :sum},
                  %{node_id: @node_2, port: :in})

    {:ok, _network_graph_process} =
        Network.start_link(@graph_1)
    Network.start()
    status = Network.get_status()
    assert status == :started
    # Make sure the network is stopped
    Network.stop()
  end

  test "Stop an ElxirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    {:ok, _network_graph_process} =
          Network.start_link(@graph_1)
    Network.start()
    Network.stop()
    status = Network.get_status()
    assert status == :stopped
  end

end
