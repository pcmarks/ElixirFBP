defmodule Streamtools.GetHTTPJSON do
  @moduledoc """
  Based on a similar component at http://blog.nytlabs.com/streamtools/
  """
  alias ElixirFBP.Component
  @behaviour ElixirFBP.Behaviour

  def description, do: "Get the JSON encoding from this url"
  def inports, do: [path: :string]
  def outports, do: [out: :string]

  def loop(inports, outports) do
    %{:path => path} = inports
    receive do
      {:path, value} ->
        inports = %{inports | :path => value}
        loop(inports, outports)
      :out when path != nil ->
        {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(path)
        e_body = Poison.decode!(body)
        send(outports[:out], {:out, e_body})
        inports = %{inports | :path => nil}
        loop(inports, outports)
    end
  end

end
