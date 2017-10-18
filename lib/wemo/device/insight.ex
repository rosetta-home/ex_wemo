defmodule WeMo.Device.Insight do
  use WeMo.Device

  defmodule Values do
    defstruct [
      state: :off,
      last_changed_at: 0,
      last_on_for: 0,
      on_today: 0,
      on_total: 0,
      timespan: 0,
      average_power: 0,
      current_power: 0,
      energy_today: 0,
      energy_total: 0,
      standby_limit: 0]
  end

  def handle_event(%{type: :InsightParams, value: value}, values) do
    [s, lca, lof, ot, otot, ts, ap, cp, et, etot, sl] = value |> String.split("|")
    values = %Values{
      state: s |> on_off?,
      last_changed_at: lca |> String.to_integer,
      last_on_for: lof |> String.to_integer,
      on_today: ot |> String.to_integer,
      on_total: otot |> String.to_integer,
      timespan: ts |> String.to_integer,
      average_power: ap |> String.to_integer,
      current_power: cp |> String.to_integer,
      energy_today: et |> String.to_integer,
      energy_total: etot |> String.to_integer,
      standby_limit: sl |> String.to_integer
    }
    Logger.debug "Got InsightParams: #{inspect values}"
    {:ok, values}
  end

  def handle_event(%{type: :BinaryState, value: value}, values) do
    [s, lca, lof, ot, otot, ts, ap, cp, et, etot] = value |> String.split("|")
    values = %Values{
      state: s |> on_off?,
      last_changed_at: lca |> String.to_integer,
      last_on_for: lof |> String.to_integer,
      on_today: ot |> String.to_integer,
      on_total: otot |> String.to_integer,
      timespan: ts |> String.to_integer,
      average_power: ap |> String.to_integer,
      current_power: cp |> String.to_integer,
      energy_today: et |> String.to_integer,
      energy_total: etot |> String.to_integer,
    }
    Logger.debug "Got BinaryState: #{inspect values}"
    {:ok, values}
  end

  def handle_event(%{type: :EnergyPerUnitCost, value: value}, values) do
    Logger.debug "Got EnergyPerUnitCost: #{value}"
  end

  def handle_event(%{type: :PluginParam, value: value}, values) do
    Logger.debug "Got PluginParam: #{value}"
  end

  def handle_event(%{type: :HomeIdRequest, value: value}, values) do
    Logger.debug "Got HomeIdRequest: #{value}"
  end

  def handle_event(%{type: other, value: value}, values) do
    Logger.error "Got #{inspect other} type: #{value}"
  end
end
