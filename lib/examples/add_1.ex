defmodule Examples.Add1 do
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "graph_n1"
  @node_1       "node_1"
  @node_2       "node_2"

  def start do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Core.Output")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :sum,
                  @node_2, :in_port)

    Graph.add_initial(fbp_graph_reg_name, 42, @node_1, :addend)
    Graph.add_initial(fbp_graph_reg_name, 24, @node_1, :augend)
    {:ok, _fbp_network_pid} =
        Network.start_link(fbp_graph_reg_name)
    Network.start()
    # Cant stop the Network before all the components have executed.
    # Need a status of paused?
    #Network.stop()
    #Network.stop_network()
  end
end
