defmodule Jsfbp.Copier do
  @moduledoc """
  ElixirFBP implementation of a JSFBP component: https://github.com/jpaulm/jsfbp
  """
  alias ElixirFBP.Component

  def inports,  do: [IN: :string]
  def outports, do: [OUT: :string]

  def loop(in_port, out) do
    receive do
      {:IN, value} ->
        out = Component.send_ip(out, value)
        loop(value, out)
    end
  end

end
