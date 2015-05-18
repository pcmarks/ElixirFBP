defmodule ElixirFBPNetworkTest do
  use ExUnit.Case, async: false
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1 "graph_1"
  test "Create an ElixirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    {:ok, _network_graph_process} =
            Network.start_link(fbp_graph_process)
    status = Network.get_status()
    assert status == :stopped
  end

  test "Start an ElxirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    {:ok, _network_graph_process} =
        Network.start_link(fbp_graph_process)
    Network.start()
    status = Network.get_status()
    assert status == :started
  end

  test "Stop an ElxirFBP Network" do
    {:ok, fbp_graph_process} = Graph.start_link(@graph_1)
    {:ok, _network_graph_process} =
          Network.start_link(fbp_graph_process)
    Network.start()
    Network.stop()
    status = Network.get_status()
    assert status == :stopped
  end

end
