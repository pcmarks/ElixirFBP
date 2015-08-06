defmodule Examples.Fbptestv1 do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptestv1"
  @node_1       "sender"
  @node_2       "copier"
  @node_3       "disc"

  def start do
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @node_1, "Jsfbp.Sender")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Jsfbp.Copier")
    Graph.add_node(fbp_graph_reg_name, @node_3, "Jsfbp.Discard")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @node_1, :OUT, @node_2, :IN)
    Graph.add_edge(fbp_graph_reg_name, @node_2, :OUT, @node_3, :IN)

    # Initialization
    Graph.add_initial(fbp_graph_reg_name, 10_000, @node_1, :COUNT)
    Graph.add_initial(fbp_graph_reg_name, self(), @node_3, :OUT)
    # Start the flow
    Network.start(@graph_1)
    receive do
      message ->
        IO.puts("All done with message #{message}")
        Network.stop
    end
  end
end
