defmodule WeMo.Client do
  use GenServer
  require Logger

  defmodule State do
    defstruct host_ip: {0, 0, 0, 0}
  end

  def start(host_ip), do: GenServer.call(__MODULE__, {:start, host_ip})

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_info({:device, %{device: %{device_type: 'urn:Belkin:device:insight:1'}} = d}, state) do
    Logger.info("Got Insight: #{inspect d.device}")
    WeMo.InsightSupervisor.start_device(d, state.host_ip)
    {:noreply, state}
  end

  def handle_info({:device, %{device: %{device_type: 'urn:Belkin:device:lightswitch:1'}} = d}, state) do
    Logger.info("Got Lightswitch: #{inspect d.device}")
    WeMo.LightSwitchSupervisor.start_device(d, state.host_ip)
    {:noreply, state}
  end

  def handle_info({:device, _other}, state) do
    {:noreply, state}
  end

  def handle_call({:start, host_ip}, _from, state) do
    SSDP.register()
    {:reply, :ok, %State{state | host_ip: host_ip}}
  end
end
