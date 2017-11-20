defmodule WeMo.Device.Humidifier do
  use WeMo.Device
  import SweetXml

  defmodule Values do
    defstruct fan_mode: nil,
      current_humidity: 0,
      desired_humidity: 0,
      water_advise: 0,
      no_water: 0,
      filter_life: 0,
      expired_filter_time: 0
  end

  def fan_mode(pid, value), do: GenServer.cast(pid, {:fan_mode, value})
  def humidity_level(pid, value), do: GenServer.cast(pid, {:humidity_level, value})
  def on(pid), do: GenServer.cast(pid, {:fan_mode, 3})
  def off(pid), do: GenServer.cast(pid, {:fan_mode, 0})

  def handle_cast({:fan_mode, value}, state) do
    %Action{
      name: "SetAttributes",
      service_type: "urn:Belkin:service:deviceevent:1",
      path: "/upnp/control/deviceevent1",
      arguments: [{"attributeList", "&lt;attribute&gt;&lt;name&gt;FanMode&lt;/name&gt;&lt;value&gt;#{value}&lt;/value&gt;&lt;/attribute&gt;"}]
    } |> send_action(state)
    {:noreply, state}
  end

  def handle_cast({:humidity_level, value}, state) do
    %Action{
      name: "SetAttributes",
      service_type: "urn:Belkin:service:deviceevent:1",
      path: "/upnp/control/deviceevent1",
      arguments: [{"attributeList", "&lt;attribute&gt;&lt;name&gt;DesiredHumidity&lt;/name&gt;&lt;value&gt;#{value}&lt;/value&gt;&lt;/attribute&gt;"}]
    } |> send_action(state)
    {:noreply, state}
  end

  def handle_event(%{type: :attributeList, value: value}, values) do
    Logger.info "#{inspect value}"
    case value do
      "0" -> {:ok, values}
      "-1" -> {:ok, values}
      v ->
        atts = value |> xpath(
          ~x"//attribute"l,
          name: ~x"./name/text()"s,
          value: ~x"./value/text()"i,
          prevalue: ~x"./prevalue/text()"i,
          ts: ~x"./ts/text()"i
        )
        fan_mode = atts |> get_attribute("FanMode", Map.get(values, :fan_mode, 0))
        current_humidity = atts |> get_attribute("CurrentHumidity", Map.get(values, :current_humidity, 0))
        desired_humidity = atts |> get_attribute("DesiredHumidity", Map.get(values, :desired_humidity, 0))
        water_advise = atts |> get_attribute("WaterAdvise", Map.get(values, :water_advise, 0))
        no_water = atts |> get_attribute("NoWater", Map.get(values, :no_water, 0))
        filter_life = atts |> get_attribute("FilterLife", Map.get(values, :filter_life, 0))
        expired_filter_time = atts |> get_attribute("ExpiredFiulterTime", Map.get(values, :expired_filter_time, 0))
        {:ok, %Values{fan_mode: fan_mode,
          current_humidity: current_humidity,
          desired_humidity: desired_humidity,
          water_advise: water_advise,
          no_water: no_water,
          filter_life: filter_life,
          expired_filter_time: expired_filter_time
        }}
    end
  end

  def handle_event(%{type: other, value: value}, values), do: Logger.error "Got #{inspect other} type: #{inspect value}"

  def get_attribute(atts, at, default \\ nil) do
    case atts |> Enum.find(fn a -> a.name == at end) do
      nil -> default
      other -> other.value
    end
  end

end
