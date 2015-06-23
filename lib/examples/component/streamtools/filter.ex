defmodule Streamtools.Filter do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def description, do: "Filter according to a value."
  def inports, do: [filter: :string, filter_value: :string, in_port: :string]
  def outports, do: [out: :string]

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
