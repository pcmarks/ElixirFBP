defmodule ElixirFBPRuntimeTest do
  use ExUnit.Case, async: false

  alias ElixirFBP.Runtime

  test "Start an ElixirFBP Runtime if not started and see if it's registered." do
    pid = Process.whereis(:ElixirFBP.Runtime)
    if ! pid do
      {:ok, pid} = Runtime.start_link
    end
    assert Process.whereis(:ElixirFBP.Runtime) == pid
  end

  test "Stop an ElixirFBP Runtime GenServer" do
    pid = Process.whereis(:ElixirFBP.Runtime)
    if ! pid do
      {:ok, pid} = Runtime.start_link
    end
    Runtime.stop
    assert Process.whereis(:ElixirFBP.Runtime) == nil
  end

  test "get default Runtime parameter values" do
    pid = Process.whereis(:ElixirFBP.Runtime)
    if ! pid do
      {:ok, pid} = Runtime.start_link
    end
    assert Runtime.get_parameter(:type) == "elixir-fbp"
    assert Runtime.get_parameter(:version) == "0.0.1"
    assert Runtime.get_parameter(:id) == "elixir-fbp"
    # :foo should not be found
    assert Runtime.get_parameter(:foo) == nil
    Runtime.stop
  end

  test "set some Runtime parameter values" do
    pid = Process.whereis(:ElixirFBP.Runtime)
    if ! pid do
      {:ok, pid} = Runtime.start_link
    end
    Runtime.set_parameter(:version, "0.0.2")
    assert Runtime.get_parameter(:version) == "0.0.2"
    Runtime.stop
  end
end
