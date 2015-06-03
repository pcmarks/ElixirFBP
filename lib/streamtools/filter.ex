defmodule Streamtools.Filter do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def inports, do: [filter: nil, filter_value: nil, in_port: nil]
  def outports, do: [out: nil]

  def loop(filter, filter_value, in_port, out) do
    receive do
      {:filter, value} ->
        loop(value, filter_value, in_port, out)
      {:filter_value, value} ->
        loop(filter, value, in_port, out)
      {:in_port, data} ->
        for datum <- data do
          if datum[filter] == filter_value do
            out = Component.send_ip(out, datum)
          end
        end
        loop(filter, filter_value, data, out)
    end
  end

end
