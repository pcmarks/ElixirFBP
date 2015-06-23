defmodule Streamtools.GetHTTPJSON do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component

  def description, do: "Get the JSON encoding from this url"
  def inports, do: [path: :string]
  def outports, do: [out: :string]

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
