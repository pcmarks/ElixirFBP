defmodule Jsfbp.Faker do
  @moduledoc """
  ElixirFBP implementation of component that fakes a computation by going to
  sleep for xx milliseconds.
  TODO: Make the sleep time an initial parameter
  """
  alias ElixirFBP.Component

  @sleep_time   20

  def inports,  do: [IN: :string]
  def outports, do: [OUT: :string]

  def loop(in_port, out) do
    receive do
      {:IN, value} ->
        # Simulate some processing
        :timer.sleep(@sleep_time)
        out = Component.send_ip(out, value)
        loop(value, out)
    end
  end

end
