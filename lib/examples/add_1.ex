defmodule Examples.Add1 do
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "graph_n1"
  @node_1       "node_1"
  @node_2       "node_2"

  def start do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @node_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Core.Output")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @node_1, :sum, @node_2, :in_port)
    # Initialization
    Graph.add_initial(fbp_graph_reg_name, "42", @node_1, :addend)
    Graph.add_initial(fbp_graph_reg_name, 24, @node_1, :augend)
    # Start the flow
    Network.start(@graph_1)
  end
end
