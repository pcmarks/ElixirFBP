defmodule ElixirFBP.Behaviour do
  @moduledoc """
  An ElixirFBP component is expected to implement this Behaviour.

  inports is a (possibly empty) keyword list of the form [inport1: type, ...]

  outports is a (possibly empty) keyword list of the form [outport1: type, ...]

  The loop function takes two arguments. The first argument is a map of input
  values. It is used as a state variable - a place to store values that have
  been received but are not ready to be used in a computation and the
  result sent out the outports.

  The second loop argument is a map of outport pids. When a value is ready to
  be sent to an outport, the outport name (an atom) is used to get the pid. The
  pid is actually a Subscription pid.

  Runnin a component in push and/or pull mode.
  TODO: describe
  """
  use Behaviour

  defcallback description :: String.t
  defcallback inports() :: [atom: atom]
  defcallback outports() :: [atom: atom]
  defcallback loop(%{}, %{}) :: any

end
