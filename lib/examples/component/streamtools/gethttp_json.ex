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
    %{:out => out} = outports
    receive do
      {:path, value} ->
        inports = %{inports | :path => value}
        {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(value)
        e_body = Poison.decode!(body)
        outports = %{outports | :out => e_body}
        loop(inports, outports)
      {:out, subscription} when out != nil ->
        send(subscription, {:out, out})
        loop(inports, outports)
    end
  end

end
