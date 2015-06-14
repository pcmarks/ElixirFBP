defmodule FBPNetwork.WsCowboy do
  @behaviour :application

  def start(_type, _args) do
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/", FBPNetwork.WsHandler, []},
        {"/static/[...]", :cowboy_static, {:priv_dir, :ws_cowboy, "static"}}
        ]}
      ])
      {:ok, _} = :cowboy.start_http(:http, 100, [{:port, 3579}],
                    [{:env, [{:dispatch, dispatch}]}])
    FBPNetwork.WsSupervisor.start_link
    ElixirFBP.Runtime.start_link
  end

  def stop(_state) do
    :ok
  end
end
