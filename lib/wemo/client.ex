defmodule WeMo.Client do
  use GenServer
  require Logger

  @http_port Application.get_env(:wemo, :http_port)

  defmodule State do
    defstruct host_ip: {0, 0, 0, 0}
  end

  def start(host_ip \\ nil), do: GenServer.call(__MODULE__, {:start, host_ip})

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
    host_ip =
      case host_ip do
        nil -> get_ipv4_address()
        host_ip -> host_ip
      end
    Logger.info "Using #{inspect host_ip}:#{@http_port} for local server"
    {:reply, :ok, %State{state | host_ip: host_ip}}
  end

  def handle_call(:register, {pid, _ref}, state) do
    Logger.debug "Registering: #{inspect pid}"
    Registry.register(WeMo.Registry, WeMo, pid)
    {:reply, :ok, state}
  end

  def get_ipv4_address() do
    :inet.getifaddrs()
    |> elem(1)
    |> Enum.find(fn {_interface, attr} ->
      Logger.debug("#{inspect attr}")
      case attr |> Keyword.get(:addr) do
        nil -> false
        {127, 0, 0, 1} -> false
        {_, _, _, _, _, _, _, _} -> false
        {_, _, _, _} -> true
      end
    end)
    |> elem(1)
    |> Keyword.fetch(:addr)
    |> elem(1)
  end
end
