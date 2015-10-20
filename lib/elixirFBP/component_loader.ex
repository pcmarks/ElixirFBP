defmodule ElixirFBP.ComponentLoader do
  @moduledoc """
  This module is responsible for loading ElixirFBP components at run time. Given
  a list of file paths, it will examine all modules, select those which implement
  the ElixirFBP.ComponentBehaviour and develop a list of Component attributes
  such as description, inports, and outports.

  This code is based on the [answer](https://groups.google.com/d/msg/elixir-lang-core/wEi95gzibLE/qFa12TLCPrMJ)
  to a question about loading Elixir modules. The code is from the hex package
  manager.
  """

  def retrieve_components(paths) do
    Enum.reduce(paths, [], fn(path, matches) ->
      {:ok, files } = :erl_prim_loader.list_dir(path |> to_char_list)
      Enum.reduce(files, matches, &match_component/2)
    end)
  end

  def is_component?(module) do
    attributes = module.__info__(:attributes)
    case attributes[:behaviour] do
      nil -> false
      behaviour -> ElixirFBP.Behaviour in behaviour
    end
  end

  def get_components(module_list) do
    Enum.map(module_list, fn(module) ->
      inports = module.inports()
      outports = module.outports()
      description = module.description()
      name = to_string(module)
      ips = Enum.map(inports, fn({id, type} = _inport) ->
        %{"id" => to_string(id), "type" => to_string(type)}
      end)
      ops = Enum.map(outports, fn({id, type} = _outport) ->
        %{"id" => to_string(id), "type" => to_string(type)}
      end)
      %{"name" => name, "description" => description,
        "inPorts" => ips, "outPorts" => ops}
    end)
  end

  @re_pattern Regex.re_pattern(~r/.*\.ex$/)

  defp match_component(filename, modules) do
    if :re.run(filename, @re_pattern, [capture: :none]) == :match do
      mod = Path.rootname(filename) |> List.to_atom
      if Code.ensure_compiled?(mod), do: [mod | modules], else: modules
    else
      modules
    end
  end
end
