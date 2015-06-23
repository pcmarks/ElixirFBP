defmodule ElixirFBP.Behaviour do
  use Behaviour

  defcallback inports() :: [ElixirAtom: ElixirAtom]
  defcallback outports() :: [ElixirAtom: ElixirAtom]
  defcallback loop(%{}, %{}) :: any
  
end
