defmodule WeMo.EventHandler do
  require Logger
  alias WeMo.Util

  @supervisors [WeMo.InsightSupervisor, WeMo.LightSwitchSupervisor, WeMo.CoffeeMakerSupervisor, WeMo.HumidifierSupervisor]

  def init({:tcp, :http}, req, _opts) do
    {:ok, req, %{}}
  end

  def handle(req, state) do
    {:ok, body, req2} = :cowboy_req.body(req)
    {sid, req3} = :cowboy_req.header("sid", req2)
    element = body |> Util.parse_event
    @supervisors |> Enum.each(fn s ->
      s |> Supervisor.which_children |> Enum.each( fn {_i, pid, _t, _m} ->
        pid |> GenServer.cast({:event, sid, element})
      end)
    end)
    {:ok, req3, state}
  end

  def terminate(_reason, _req, _state), do: :ok
end
