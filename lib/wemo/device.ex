defmodule WeMo.Device do
  @callback handle_event(event :: String.t) :: {:ok, %{}}

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
        defstruct device: %{}, sids: [], values: %{}, host_ip: {0, 0, 0, 0}
      end

      def on(pid), do: GenServer.cast(pid, :on)
      def off(pid), do: GenServer.cast(pid, :off)
      def state(pid), do: GenServer.call(pid, :state)
      def insight(pid), do: GenServer.cast(pid, :insight)

      def start_link(device, host_ip) do
        GenServer.start_link(__MODULE__, [device, host_ip], name: :"#{device.device.udn}")
      end

      def init([device, host_ip]) do
        Process.send_after(self(), :subscribe, 0)
        {:ok, %State{device: device, host_ip: host_ip}}
      end

      def handle_call(:state, _from, state), do: {:reply, state, state}

      def handle_cast({:device_update, device, host_ip}, state) do
        Logger.info("Device Updating: #{inspect device.device.udn}")
        Process.send_after(self(), :subscribe, 0)
        {:noreply, %State{state | device: device, host_ip: host_ip}}
      end

      def handle_cast({:event, sid, event}, state) do
        with true <- sid in state.sids,
          {:ok, values} <- event |> __MODULE__.handle_event()
        do
          {:noreply, %State{state | values: values}}
        else
          _other -> {:noreply, state}
        end
      end

      def handle_cast(:on, state) do
        %Action{
          name: "SetBinaryState",
          service_type: "urn:Belkin:service:basicevent:1",
          arguments: [{"BinaryState", "1"}]
        } |> send_action(state.device.uri.authority)
        {:noreply, state}
      end

      def handle_cast(:off, state) do
        %Action{
          name: "SetBinaryState",
          service_type: "urn:Belkin:service:basicevent:1",
          arguments: [{"BinaryState", "0"}]
        } |> send_action(state.device.uri.authority)
        {:noreply, state}
      end

      def handle_cast(:insight, state) do
        %Action{
          name: "GetPower",
          service_type: "urn:Belkin:service:insight:1",
          arguments: [{"InstantPower", "1"}]
        } |> send_action(state.device.uri.authority)
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
        Task.start(fn ->
          sids =
            device.device.service_list |> Enum.map(fn service ->
              case HTTPoison.request(:subscribe, "#{device.uri.authority}#{service.event_sub_url}", "", headers) do
                {:ok, resp} ->
                  Logger.info "SUCCESS: #{service.event_sub_url}"
                  (resp.headers |> Map.new)["SID"]
                {:error, resp} ->
                  Logger.error("#{service.event_sub_url}: #{inspect resp}")
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

      defp send_action(%Action{} = action, address) do
        Task.start(fn ->
          headers = %{"SOAPACTION" => "\"#{action.service_type}##{action.name}\"", "Content-Type" => "text/xml; charset=\"utf-8\"", "Accept" => ""}
          body = EEx.eval_file(@request_template, [action: action])
          Logger.info "#{inspect "http://#{address}/upnp/control/basicevent1"}"
          Logger.info "#{inspect headers}"
          Logger.info "#{body}"
          case HTTPoison.post("http://#{address}/upnp/control/basicevent1", body, headers) do
            {:ok, %HTTPoison.Response{status_code: 200} = r} -> Logger.info("#{inspect r}")
            {:ok, %HTTPoison.Response{status_code: 500} = r} -> Logger.error("#{inspect r}")
            {:error, reason} -> Logger.error("#{reason}")
          end
        end)
      end

      def handle_event(event) do
        Logger.info("#{__MODULE__} received event: #{inspect event}")
        {:ok, %{}}
      end

      defoverridable [handle_event: 1]
    end
  end
end
