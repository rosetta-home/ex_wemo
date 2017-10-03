defmodule WeMo do
  require Logger

  def register do
    WeMo.Client |> GenServer.call(:register)
  end

  def dispatch(type, event) do
    Logger.debug "Dispatching: #{inspect type} - #{inspect event}"
    case Registry.lookup(WeMo.Registry, type) do
      [] -> Logger.debug "No Registrations for #{inspect type}"
      _ ->
        Registry.dispatch(WeMo.Registry, type, fn entries ->
          for {_module, pid} <- entries, do: send(pid, event)
        end)
    end
    Logger.debug "Dispatched: #{inspect event}"
    event
  end
end
