defmodule ElixirFBPGraphTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  # Testing parameters
  @graph_1 "graph_g1"
  @node_1 "node_1"
  @node_2 "node_2"

  test "Create and persist a graph with default metadata" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert :digraph == elem(fbp_graph.graph, 0)
  end

  test "Clear an FBP graph" do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert :digraph.no_edges(fbp_graph.graph) == 0
    assert :digraph.no_vertices(fbp_graph.graph) == 0
    Network.stop(@graph_1)
    assert :ok = Network.stop
  end

  test "Clear an FBP graph and change its description" do
    Network.start_link
    {:ok, fbp_graph_reg_name} =Network.clear(@graph_1)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert nil == fbp_graph.description
    {:ok, ^fbp_graph_reg_name} =
          Network.clear(@graph_1, %{description: "this is a test"})
    fbp_graph = Graph.get(fbp_graph_reg_name)
    assert "this is a test" == fbp_graph.description
    Network.stop(@graph_1)
    assert :ok = Network.stop
  end

  test "Add a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert node_id in nodes == true
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    assert label.inports == [{:addend, nil}, {:augend, nil}]
  end

  test "Add a node; check default metadata" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name,
                              @node_1,
                              "Math.Add")
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert node_id in nodes == true
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    assert label.inports == [{:addend, nil}, {:augend, nil}]
    assert Map.fetch!(label.metadata, :number_of_processes) == 1
  end

  test "Add a node with metadata" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name,
                              @node_1,
                              "Math.Add",
                              %{number_of_processes: 4})
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert node_id in nodes == true
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    assert label.inports == [{:addend, nil}, {:augend, nil}]
    assert Map.fetch!(label.metadata, :number_of_processes) == 4
  end

  test "Get the info associated with a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    node_id = Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    {_node_id, label} = Graph.get_node(fbp_graph_reg_name, node_id)
    assert label.component == "Math.Add"
  end

  test "Remove a node" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    result = Graph.remove_node(fbp_graph_reg_name, @node_1)
    assert result == true
    nodes = Graph.nodes(fbp_graph_reg_name)
    assert @node_1 in nodes == false
  end

  test "Add an edge between two nodes" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_edge_id, node1, node2, label} = :digraph.edge(fbp_graph.graph, edge)
    assert node1 == @node_1
    assert node2 == @node_2
    assert label.src_port == :sum
    assert label.tgt_port == :addend
  end

  test "Remove an edge between two nodes" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    # First add an edge
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Math.Add")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    # Now remove it
    result = Graph.remove_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :addend)
    assert result == true
  end

  test "Add an initial value to a node port without conversion" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    result = Graph.add_initial(fbp_graph_reg_name, 27, @node_1, :addend)
    assert result == 27
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, @node_1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == 27
  end

  test "Add an initial value to a node port with conversion" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    result = Graph.add_initial(fbp_graph_reg_name, "27", @node_1, :addend)
    assert result == 27
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, @node_1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == 27
  end

  test "Remove an initial value from a node port" do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_initial(fbp_graph_reg_name, 27, @node_1, :addend)
    result = Graph.remove_initial(fbp_graph_reg_name, @node_1, :addend)
    assert result == nil
    # Double-check that the value is = nil
    fbp_graph = Graph.get(fbp_graph_reg_name)
    {_node_id, label} = :digraph.vertex(fbp_graph.graph, @node_1)
    inports = label.inports
    port_value = inports[:addend]
    assert port_value == nil
  end
end
