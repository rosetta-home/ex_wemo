defmodule WeMo.DeviceSupervisor do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(WeMo.Device, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def start_device(device) do
    Logger.info "Starting device: #{inspect device}"
    Supervisor.start_child(__MODULE__, [device])
  end
end
