defmodule WeMo.Device.CoffeeMaker do
  use WeMo.Device
  import SweetXml

  @modes [
    "Refill",
    "PlaceCarafe",
    "RefillWater",
    "Ready",
    "Brewing",
    "Brewed",
    "CleaningBrewing",
    "CleaningSoaking",
    "BrewFailCarafeRemoved"
  ]

  defmodule Values do
    defstruct mode: nil, mode_time: 0, mode_val: 0
  end

  def on(pid), do: GenServer.cast(pid, :coffee_on)
  def off(pid), do: GenServer.cast(pid, :coffee_off)

  def handle_cast(:coffee_on, state) do
    %Action{
      name: "SetAttributes",
      service_type: "urn:Belkin:service:deviceevent:1",
      path: "/upnp/control/deviceevent1",
      arguments: [{"attributeList", "&lt;attribute&gt;&lt;name&gt;Mode&lt;/name&gt;&lt;value&gt;4&lt;/value&gt;&lt;/attribute&gt;"}]
    } |> send_action(state)
    {:noreply, state}
  end

  def handle_cast(:coffee_off, state) do
    Logger.error("Currently you cannot stop brewing through the SOAP interface. Please hit the physical button on the coffee maker")
    {:noreply, state}
  end

  def handle_event(%{type: :attributeList, value: value}, values) do
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
        mode_val = atts |> get_attribute("Mode", Map.get(values, :mode_val, 0))
        mode = @modes |> Enum.at(mode_val)
        mode_time = atts |> get_attribute("ModeTime", Map.get(values, :mode_time))
        {:ok, %Values{mode: mode, mode_time: mode_time, mode_val: mode_val}}
    end
  end

  def handle_event(%{type: other, value: value}, values), do: Logger.error "Got #{inspect other} type: #{value}"

  def get_attribute(atts, at, default \\ nil) do
    case atts |> Enum.find(fn a -> a.name == at end) do
      nil -> default
      other -> other.value
    end
  end

end
