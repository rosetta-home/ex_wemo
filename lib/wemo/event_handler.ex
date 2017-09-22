defmodule WeMo.EventHandler do
  require Logger

  def init({:tcp, :http}, req, opts) do
    {:ok, req, %{}}
  end

  def handle(req, state) do
    {:ok, body, req2} = :cowboy_req.body(req)
    {sid, req3} = :cowboy_req.header("sid", req2)
    WeMo.DeviceSupervisor |> Supervisor.which_children |> Enum.each( fn {_i, pid, _t, _m} ->
      pid |> WeMo.Device.update({sid, body})
    end)
    {:ok, req3, state}
  end

  def terminate(_reason, req, state), do: :ok
end
