defmodule Examples.Fbptest02 do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptest02"
  @node_1       "reader"
  @node_2       "copier"
  @node_3       "recvr"

  def start do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @node_1, "Jsfbp.Reader")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Jsfbp.Copier")
    Graph.add_node(fbp_graph_reg_name, @node_3, "Jsfbp.Recvr")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @node_1, :OUT, @node_2, :IN)
    Graph.add_edge(fbp_graph_reg_name, @node_2, :OUT, @node_3, :IN)

    # Initialization
    Graph.add_initial(fbp_graph_reg_name, "lib/examples/data/text.txt", @node_1, :FILE)
    Graph.add_initial(fbp_graph_reg_name, self(), @node_3, :OUT)
    # Start the flow
    {:ok, _fbp_network_pid} =
        Network.start_link(fbp_graph_reg_name)
    Network.start()
    receive do
      message ->
        IO.puts("All done! with message #{message}")
        Network.stop
        Network.stop_network
    end
  end

  def time_it do
    :timer.tc(fn -> start end, [])
  end
end
