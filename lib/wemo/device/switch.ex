defmodule WeMo.Device.Switch do
  use WeMo.Device

  defmodule Values do
    defstruct state: :off
  end

  def handle_event(%{type: :BinaryState, value: value}, values) do
    [s] = value |> String.split("|")
    values = %Values{
      state: s |> on_off?
    }
    Logger.debug "Got BinaryState: #{inspect values}"
    {:ok, values}
  end

  def handle_event(%{type: other, value: value}, values), do: Logger.error "Got #{inspect other} type: #{value}"

end
