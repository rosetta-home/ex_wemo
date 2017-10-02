defmodule WeMo.DeviceSupervisor do
  defmacro __using__(module: module) do
    quote bind_quoted: [module: module] do
      use Supervisor
      require Logger

      @device_module module

      def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
      end

      def init(:ok) do
        children = [
          worker(@device_module, [], restart: :transient)
        ]
        supervise(children, strategy: :simple_one_for_one)
      end

      def start_device(device, host_ip) do
        Logger.info "Starting device: #{inspect device}"
        case Supervisor.start_child(__MODULE__, [device, host_ip]) do
          {:ok, pid} -> :ok
          {:error, {:already_started, pid}} -> pid |> GenServer.cast({:device_update, device, host_ip})
          other -> Logger.error("#{@device_module} is not able to be started: #{inspect other}")
        end
      end
    end
  end
end

defmodule WeMo.InsightSupervisor do
  use WeMo.DeviceSupervisor, module: WeMo.Device.Insight
end

defmodule WeMo.LightSwitchSupervisor do
  use WeMo.DeviceSupervisor, module: WeMo.Device.LightSwitch
end
