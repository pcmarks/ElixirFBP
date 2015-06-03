defmodule Streamtools.GetHTTPJSON do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def inports, do: [path: nil]
  def outports, do: [out: nil]

  def loop(path, out) do
    receive do
      {:path, value} ->
        {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(value)
        e_body = Poison.decode!(body)
        out = Component.send_ip(out, e_body)
        loop(value, out)
    end
  end

end
