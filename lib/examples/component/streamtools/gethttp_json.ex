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
        out = Component.send_ip(out, e_body)
        outports = %{outports | :out => out}
        loop(inports, outports)
    end
  end

end
