defmodule WeMo.Util do
  import SweetXml
  require Logger

  def parse_event(event) do
    event
    |> xpath(~x"//e:propertyset/e:property/*[1]"e)
    |> (fn(element) ->
      case element do
        nil -> event |> parse_action
        element -> %{type: element |> elem(1), value: element |> xpath(~x"./text()"s)}
      end
    end).()
  end

  def parse_action(action) do
    action
    |> xpath(~x"//s:Envelope/s:Body/*[1]/*[1]"e)
    |> (fn(element) ->
      case element do
        nil -> nil
        element -> %{type: element |> elem(1), value: element |> xpath(~x"./text()"s)}
      end
    end).()
  end

  def get_ipv4_address() do
    :inet.getifaddrs()
    |> elem(1)
    |> Enum.find(fn {_interface, attr} ->
      case attr |> Keyword.get_values(:addr) do
        [] -> false
        list -> list |> Enum.find(fn(addr) ->
          case addr do
            nil -> false
            {127, 0, 0, 1} -> false
            {_, _, _, _, _, _, _, _} -> false
            {_, _, _, _} -> true
          end
        end)
      end
    end)
    |> elem(1)
    |> Keyword.fetch(:addr)
    |> elem(1)
  end
end
