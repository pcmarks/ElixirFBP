defmodule Examples.Fbptestv1Multi do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  This is the multi process version of Examples.Fbptestv1.ex
  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "fbptestv1"
  @sender       "sender"
  @faker        "faker"
  @disc         "disc"

  @no_of_processes_def  1
  @no_of_messages_def   1_000

  def start(no_of_messages \\ @no_of_messages_def, no_of_processes \\ @no_of_processes_def) do
    {:ok, fbp_graph_reg_name} = Network.clear(@graph_1)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @sender, "Jsfbp.Sender")
    Graph.add_node(fbp_graph_reg_name, @faker, "Jsfbp.Faker",
                   %{:number_of_processes => no_of_processes })
    Graph.add_node(fbp_graph_reg_name, @disc, "Jsfbp.Discard")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @sender, :OUT, @faker, :IN)
    Graph.add_edge(fbp_graph_reg_name, @faker, :OUT, @disc, :IN)

    # Initialization
    Graph.add_initial(fbp_graph_reg_name, no_of_messages, @sender, :COUNT)
    Graph.add_initial(fbp_graph_reg_name, self(), @disc, :OUT)
    # Start the flow
    Network.start(@graph_1)
    receive do
      message ->
        IO.puts("All done with message #{message}")
        Network.stop
    end
  end

  def time_it(no_of_messages \\ @no_of_messages_def,
              no_of_processes \\ @no_of_processes_def) do
    :timer.tc(__MODULE__, :start, [no_of_messages, no_of_processes])
  end
end
