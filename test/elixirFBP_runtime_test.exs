defmodule ElixirFBPRuntimeTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Runtime

  test "Start an ElixirFBP Runtime and see if it's registered." do
    {:ok, pid} = Runtime.start_link
    assert Process.whereis(:ElixirFBP.Runtime) == pid
  end

  test "Stop an ElixirFBP Runtime GenServer" do
    {:ok, _pid} = Runtime.start_link
    Runtime.stop
    assert Process.whereis(:ElixirFBP.Runtime) == nil
  end

end
