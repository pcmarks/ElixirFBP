defmodule Examples.Fbptest01 do
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptest01"
  @node_1       "sender"
  @node_2       "copier"
  @node_3       "recvr"

  def start do
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @node_1, "Jsfbp.Sender")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Jsfbp.Copier")
    Graph.add_node(fbp_graph_reg_name, @node_3, "Jsfbp.Recvr")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @node_1, :OUT, @node_2, :IN)
    Graph.add_edge(fbp_graph_reg_name, @node_2, :OUT, @node_3, :IN)
    # Initialization
    Graph.add_initial(fbp_graph_reg_name, 1_000, @node_1, :COUNT)
    Graph.add_initial(fbp_graph_reg_name, self(), @node_3, :OUT)
    # Start the flow
    Network.start(@graph_1)
    receive do
      message ->
        IO.puts("All done! with message #{message}")
        Network.stop
    end
  end

  def time_it do
    :timer.tc(fn -> start end, [])
  end
end
