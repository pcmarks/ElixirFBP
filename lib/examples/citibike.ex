defmodule Examples.Citibike do
  @moduledoc """
  This example is based on the one developed for the Streamtools system:
  http://blog.nytlabs.com/2014/03/12/streamtools-a-graphical-tool-for-working-with-streams-of-data/
  It does not include the last step - a mask function.

  """
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @citibike       "citibike"
  @ticker         "ticker"
  @map            "map"
  @getHTTP        "getHTTP"
  @unpack         "unpack"
  @filter         "filter"
  @output         "output"

  def start do
    Network.start_link
    {:ok, fbp_graph_reg_name} = Network.clear(@citibike)
    # Add the components to the graph
    Graph.add_node(fbp_graph_reg_name, @ticker, "Streamtools.Ticker")
    Graph.add_node(fbp_graph_reg_name, @map, "Streamtools.Map")
    Graph.add_node(fbp_graph_reg_name, @getHTTP, "Streamtools.GetHTTPJSON")
    Graph.add_node(fbp_graph_reg_name, @unpack, "Streamtools.Unpack")
    Graph.add_node(fbp_graph_reg_name, @filter, "Streamtools.Filter")
    Graph.add_node(fbp_graph_reg_name, @output, "Core.Output")
    # Connect the components
    Graph.add_edge(fbp_graph_reg_name, @ticker, :out, @map, :in_port)
    Graph.add_edge(fbp_graph_reg_name, @map, :out, @getHTTP, :path)
    Graph.add_edge(fbp_graph_reg_name, @getHTTP, :out, @unpack, :in_port)
    Graph.add_edge(fbp_graph_reg_name, @unpack, :out, @filter, :in_port)
    Graph.add_edge(fbp_graph_reg_name, @filter, :out, @output, :in_port)
    # Set initial values
    Graph.add_initial(fbp_graph_reg_name, 10_000, @ticker, :interval)
    Graph.add_initial(fbp_graph_reg_name,
                      "http://www.citibikenyc.com/stations/json",
                      @map, :map)
    Graph.add_initial(fbp_graph_reg_name, "stationBeanList", @unpack, :part)
    Graph.add_initial(fbp_graph_reg_name, "stationName", @filter, :filter)
    Graph.add_initial(fbp_graph_reg_name, "W 41 St & 8 Ave", @filter, :filter_value)
    # Start the flow
    Network.start(@citibike)
  end
end
