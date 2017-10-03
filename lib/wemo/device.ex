defmodule WeMo.Device do
  alias WeMo.Util

  @callback handle_event(event :: String.t) :: {:ok, %{}} | :ok

  defmacro __using__(_) do
    quote do
      use GenServer
      require Logger
      @behaviour WeMo.Device
      @http_port Application.get_env(:wemo, :http_port)
      @request_template Path.join(:code.priv_dir(:wemo), "request.soap.eex")

      defmodule Action do
        defstruct name: nil, service_type: nil, arguments: []
      end

      defmodule State do
        defstruct pid: nil, device: %{}, sids: [], values: %{}, host_ip: {0, 0, 0, 0}
      end

      def on(pid), do: GenServer.cast(pid, :on)
      def off(pid), do: GenServer.cast(pid, :off)
      def state(pid), do: GenServer.call(pid, :state)
      def insight(pid), do: GenServer.cast(pid, :insight)

      def start_link(device, host_ip) do
        pid = :"#{device.device.udn}"
        GenServer.start_link(__MODULE__, [device, host_ip, pid], name: pid)
      end

      def init([device, host_ip, pid]) do
        Process.send_after(self(), :subscribe, 0)
        {:ok, %State{device: device, host_ip: host_ip, pid: pid}}
      end

      def handle_call(:state, _from, state), do: {:reply, state, state}

      def handle_cast({:device_update, device, host_ip}, state) do
        Logger.info("Device Updating: #{inspect device.device.udn}")
        Process.send_after(self(), :subscribe, 0)
        {:noreply, %State{state | device: device, host_ip: host_ip}}
      end

      def handle_cast({:event, nil, event}, state), do: do_handle_event(event, state)
      def handle_cast({:event, sid, event}, state) do
        case sid in state.sids do
          true -> do_handle_event(event, state)
          _ -> {:noreply, state}
        end
      end

      def do_handle_event(event, state) do
        state  =
          case event |> __MODULE__.handle_event() do
            {:ok, values} ->
              state = %State{state | values: values}
              WeMo.dispatch(WeMo, {:device, state})
              state
            _ -> state
          end
        {:noreply, state}
      end

      def handle_cast(:on, state) do
        %Action{
          name: "SetBinaryState",
          service_type: "urn:Belkin:service:basicevent:1",
          arguments: [{"BinaryState", "1"}]
        } |> send_action(state)
        {:noreply, state}
      end

      def handle_cast(:off, state) do
        %Action{
          name: "SetBinaryState",
          service_type: "urn:Belkin:service:basicevent:1",
          arguments: [{"BinaryState", "0"}]
        } |> send_action(state)
        {:noreply, state}
      end

      def handle_cast(:insight, state) do
        %Action{
          name: "GetPower",
          service_type: "urn:Belkin:service:insight:1",
          arguments: [{"InstantPower", "1"}]
        } |> send_action(state)
        {:noreply, state}
      end

      def handle_info(:subscribe, state) do
        state.device |> subscribe(state.host_ip)
        {:noreply, state}
      end

      def handle_info({:sids, sids}, state), do: {:noreply, %State{state | sids: sids}}

      defp subscribe(device, host_ip) do
        headers = %{"CALLBACK" => "<http://#{:inet.ntoa(host_ip)}:#{@http_port}>", "NT" => "upnp:event", "TIMEOUT" => "Second-600"}
        s = self()
        WeMo.TaskSupervisor |> Task.Supervisor.start_child(fn ->
          sids =
            device.device.service_list |> Enum.map(fn service ->
              case HTTPoison.request(:subscribe, "#{device.uri.authority}#{service.event_sub_url}", "", headers) do
                {:ok, resp} ->
                  Logger.info "#{device.device.udn} Event Subscription Successful: #{service.event_sub_url}"
                  (resp.headers |> Map.new)["SID"]
                {:error, resp} ->
                  Logger.error("#{device.device.udn} Event Subscription failed #{service.event_sub_url}: #{inspect resp}")
                  nil
              end
            end)
            |> Enum.filter(fn sid ->
              case sid do
                nil -> false
                _ -> true
              end
            end)
          send(s, {:sids, sids})
        end)
      end

      defp send_action(%Action{} = action, state) do
        WeMo.TaskSupervisor |> Task.Supervisor.start_child(fn ->
          headers = %{
            "SOAPACTION" => "\"#{action.service_type}##{action.name}\"",
            "Content-Type" => "text/xml; charset=\"utf-8\"",
            "Accept" => "*/*",
            "Connection" => "keep-alive"
          }
          body = EEx.eval_file(@request_template, [action: action])
          case HTTPoison.post("http://#{state.device.uri.authority}/upnp/control/basicevent1", body, headers) do
            {:ok, %HTTPoison.Response{status_code: 200} = r} ->
              state.pid |> GenServer.cast({:event, nil, r.body |> Util.parse_event()})
            {:ok, %HTTPoison.Response{status_code: 500} = r} -> Logger.error("#{inspect r}")
            {:error, reason} -> Logger.error("#{inspect reason}")
          end
        end)
      end

      def handle_event(event) do
        Logger.debug("#{__MODULE__} received event: #{inspect event}")
        {:ok, %{}}
      end

      defp on_off?("8"), do: :on
      defp on_off?("1"), do: :on
      defp on_off?("0"), do: :off

      defoverridable [handle_event: 1]
    end
  end
end
