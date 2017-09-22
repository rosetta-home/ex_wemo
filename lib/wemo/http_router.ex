defmodule WeMo.HTTPRouter do

  def start_link do
    port = Application.get_env(:wemo, :http_port, 8080)
    dispatch = :cowboy_router.compile([
      { :_,
        [
          {"/", WeMo.EventHandler, []},
        ]}
      ])
      {:ok, _} = :cowboy.start_http(:interface_http,
        10,
        [{:ip, {0,0,0,0}}, {:port, port}],
        [{:env, [{:dispatch, dispatch}]}]
      )
  end


end
