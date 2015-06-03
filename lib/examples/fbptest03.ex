defmodule Examples.Fbptest03 do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptest03"
  @sender       "sender"
  @reader       "reader"
  @copier       "copier"
  @recvr        "recvr"

  def start do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @sender, "Jsfbp.Sender")
    Graph.add_node(fbp_graph_reg_name, @reader, "Jsfbp.Reader")
    Graph.add_node(fbp_graph_reg_name, @copier, "Jsfbp.Copier")
    Graph.add_node(fbp_graph_reg_name, @recvr,  "Jsfbp.Recvr")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @sender, :OUT, @copier, :IN)
    Graph.add_edge(fbp_graph_reg_name, @reader, :OUT, @copier, :IN)
    Graph.add_edge(fbp_graph_reg_name, @copier, :OUT, @recvr, :IN)

    # Initialization
    Graph.add_initial(fbp_graph_reg_name, 20, @sender, :COUNT)
    Graph.add_initial(fbp_graph_reg_name, "lib/examples/data/text.txt", @reader, :FILE)
    Graph.add_initial(fbp_graph_reg_name, self(), @recvr, :OUT)
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
