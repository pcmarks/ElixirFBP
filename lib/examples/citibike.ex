defmodule Examples.Citibike do
  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  @graph_1      "citibike"
  @node_1       "ticker"
  @node_2       "map"
  @node_3       "getHTTP"
  @node_4       "unpack"
  @node_5       "filter"
  @node_6       "output"

  def start do
    {:ok, fbp_graph_reg_name} = Graph.start_link(@graph_1)
    Graph.add_node(fbp_graph_reg_name, @node_1, "Streamtools.Ticker")
    Graph.add_node(fbp_graph_reg_name, @node_2, "Streamtools.Map")
    Graph.add_node(fbp_graph_reg_name, @node_3, "Streamtools.GetHTTPJSON")
    Graph.add_node(fbp_graph_reg_name, @node_4, "Streamtools.Unpack")
    Graph.add_node(fbp_graph_reg_name, @node_5, "Streamtools.Filter")
    Graph.add_node(fbp_graph_reg_name, @node_6, "Core.Output")
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_1, :out,
                  @node_2, :in_port)
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_2, :out,
                  @node_3, :path)
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_3, :out,
                  @node_4, :in_port)
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_4, :out,
                  @node_5, :in_port)
    _edge = Graph.add_edge(
                  fbp_graph_reg_name,
                  @node_5, :out,
                  @node_6, :in_port)

    Graph.add_initial(fbp_graph_reg_name, 10_000, @node_1, :interval)
    Graph.add_initial(fbp_graph_reg_name,
                      "http://www.citibikenyc.com/stations/json",
                      @node_2, :map)
    Graph.add_initial(fbp_graph_reg_name, "stationBeanList", @node_4, :part)
    Graph.add_initial(fbp_graph_reg_name, "stationName", @node_5, :filter)
    Graph.add_initial(fbp_graph_reg_name, "W 41 St & 8 Ave", @node_5, :filter_value)

    {:ok, _fbp_network_pid} =
        Network.start_link(fbp_graph_reg_name)
    Network.start()
    # Cant stop the Network before all the components have executed.
    # Need a wait?
    #Network.stop()
    #Network.stop_network()
  end
end
