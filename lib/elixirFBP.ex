defmodule ElixirFBP do
  @moduledoc """
  ElixirFBP is an implementation of the flow-based programming (FBP) technique.
  An FBP program is represented by a directed graph where the nodes are
  components that can receive Information Packets (IPs) via in ports and send
  IPs - typically after some computation - out the out ports.

  In ElixirFBP, each component is a module that must specify the names of its
  in and out ports and it must implement a loop function that is responsible for
  maintaining state and sending computed values to the out ports.

  An FBP program is created by adding components to an ElixrFBP.Graph (a gen_server).
  The graph, in turn, is kept inside and managed by an ElixirFBP.Network
  (a gen_server).

  """
end
