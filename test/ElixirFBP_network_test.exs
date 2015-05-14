defmodule ElixirFBPNetworkTest do
  use ExUnit.Case, async: false

  test "Create an ElixirFBP Network" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link(:graph_1)
    {:ok, _network_graph_process} = ElixirFBP.Network.start_link(:graph_1)
    status = ElixirFBP.Network.get_status()
    assert status == :stopped
  end

  test "Start an ElxirFBP Network" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link(:graph_1)
    {:ok, _network_graph_process} = ElixirFBP.Network.start_link(:graph_1)
    ElixirFBP.Network.start()
    status = ElixirFBP.Network.get_status()
    assert status == :started
  end

  test "Stop an ElxirFBP Network" do
    {:ok, _fbp_graph_process} = ElixirFBP.Graph.start_link(:graph_1)
    {:ok, _network_graph_process} = ElixirFBP.Network.start_link(:graph_1)
    ElixirFBP.Network.start()
    ElixirFBP.Network.stop()
    status = ElixirFBP.Network.get_status()
    assert status == :stopped
  end

end
