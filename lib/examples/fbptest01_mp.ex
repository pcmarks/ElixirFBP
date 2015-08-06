defmodule Examples.Fbptest01Mp do
  @moduledoc """
  The multi-process version of the Fbptest01 example.
  Note the extra metadata Map argument contining the key :number_of_processes
  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptest01"
  @node_1       "sender"
  @node_2       "copier"
  @node_3       "recvr"

  def start do
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @node_1, "Jsfbp.Sender",
                   %{number_of_processes: 1})
    Graph.add_node(fbp_graph_reg_name, @node_2, "Jsfbp.Copier")
    Graph.add_node(fbp_graph_reg_name, @node_3, "Jsfbp.Recvr")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @node_1, :OUT, @node_2, :IN)
    Graph.add_edge(fbp_graph_reg_name, @node_2, :OUT, @node_3, :IN)
    # Initialization
    Graph.add_initial(fbp_graph_reg_name, 1_000, @node_1, :COUNT)
    # Start the flow
    Network.start(@graph_1)
  end
end
