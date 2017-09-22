defmodule WeMo.Device do
  use GenServer
  require Logger

  @request_template Path.join(:code.priv_dir(:wemo), "request.soap.eex")

  defmodule Action do
    defstruct name: nil, service_type: nil, arguments: []
  end

  defmodule State do
    defstruct device: %{}, sids: []
  end

  def update(pid, {sid, data}) do
    GenServer.cast(pid, {:sid, sid, data})
  end

  def start_link(device) do
    Logger.info("Device Starting: #{inspect device.device.udn}")
    GenServer.start_link(__MODULE__, device, name: :"#{device.device.udn}")
  end

  def init(device) do
    Process.send_after(self(), :subscribe, 0)
    {:ok, %State{device: device}}
  end

  def handle_info(:subscribe, state) do
    sids = state.device |> subscribe()
    Logger.info "SIDS: #{inspect sids}"
    {:noreply, %State{state | sids: sids}}
  end

  def handle_cast({:sid, sid, data}, %State{sids: sids} = state) do
    case sid in sids do
      true -> Logger.info "#{state.device.device.udn} got update: #{data}"
      false -> nil
    end
    {:noreply, state}
  end

  def handle_call(:get_insights, _from, state) do
    action = %Action{name: "GetPower", service_type: "urn:Belkin:service:insight:1", arguments: [{"InstantPower", "1"}]}
    headers = %{"SOAPACTION" => "\"urn:Belkin:service:insight:1#GetPower\"", "Content-Type" => "text/xml"}
    state.insights |> Enum.each(fn i ->
      body = EEx.eval_file(@request_template, [action: action])
      Logger.info "#{body}"
      case HTTPoison.post("http://#{i.uri.authority}/upnp/control/insight1", body, headers) do
        {:ok, %HTTPoison.Response{status_code: 200} = r} -> Logger.info("#{inspect r}")
        {:ok, %HTTPoison.Response{status_code: 500} = r} -> Logger.error("#{inspect r}")
        {:error, reason} -> Logger.error("#{reason}")
      end
    end)
    {:reply, :ok, state}
  end

  def subscribe(device) do
    headers = %{"CALLBACK" => "<http://192.168.1.112:8080>", "NT" => "upnp:event", "TIMEOUT" => "Second-600"}
    device.device.service_list |> Enum.map(fn service ->
      case HTTPoison.request(:subscribe, "#{device.uri.authority}#{service.event_sub_url}", "", headers) do
        {:ok, resp} -> (resp.headers |> Map.new)["SID"]
        {:error, resp} ->
          Logger.error("#{inspect resp}")
          nil
      end
    end)
    |> Enum.uniq
    |> Enum.filter(fn sid ->
      case sid do
        nil -> false
        _ -> true
      end
    end)
  end
end
