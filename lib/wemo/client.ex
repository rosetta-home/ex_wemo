defmodule WeMo.Client do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    SSDP.register()
    {:ok, %{}}
  end

  def handle_info({:device, %{device: %{device_type: 'urn:Belkin:device:insight:1'}} = d}, state) do
    Logger.info("Got Insight: #{inspect d.device}")
    WeMo.DeviceSupervisor.start_device(d)
    {:noreply, state}
  end
  def handle_info({:device, %{device: %{device_type: 'urn:Belkin:device:lightswitch:1'}} = d}, state) do
    Logger.info("Got Lightswitch: #{inspect d.device}")
    WeMo.DeviceSupervisor.start_device(d)
    {:noreply, state}
  end

  def handle_info({:device, other}, state) do
    #Logger.info("Other Device: #{inspect other}")
    {:noreply, state}
  end

  def subscribe(device) do
    headers = %{"CALLBACK" => "<http://192.168.1.112:8080>", "NT" => "upnp:event", "TIMEOUT" => "Second-600"}
    device.device.service_list |> Enum.each(fn service ->
      case HTTPoison.request(:subscribe, "#{device.uri.authority}#{service.event_sub_url}", "", headers) do
        {:ok, resp} -> Logger.info("#{inspect resp}")
        {:error, resp} -> Logger.error("#{inspect resp}")
      end
    end)
  end
end
