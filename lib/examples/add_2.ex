defmodule Examples.Add2 do
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "graph_n2"
  @add_1        "add_1"
  @node_2       "node_2"
  @add_2        "add_2"

  def start do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @add_1, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @add_2, "Math.Add")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Core.Output")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @add_1, :sum, @add_2, :augend)
    Graph.add_edge(fbp_graph_reg_name, @add_2, :sum, @node_2, :in_port)
    # Initialization
    Graph.add_initial(fbp_graph_reg_name, "42", @add_1, :addend)
    Graph.add_initial(fbp_graph_reg_name, 24, @add_1, :augend)
    Graph.add_initial(fbp_graph_reg_name, 33, @add_2, :addend)

    # Start the flow
    Network.start(@graph_1)
  end
end
