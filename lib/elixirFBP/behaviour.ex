defmodule ElixirFBP.Behaviour do
  use Behaviour

  defcallback description :: String.t
  defcallback inports() :: [atom: atom]
  defcallback outports() :: [atom: atom]
  defcallback loop(%{}, %{}) :: any

end
