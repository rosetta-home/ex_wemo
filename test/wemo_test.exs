defmodule WemoTest do
  use ExUnit.Case
  doctest WeMo

  test "test actual device on network" do
    WeMo.Client.start()
    WeMo.register()
    SSDP.Client.start()
    assert_receive {:device, %{device: %{}}}, 10_000
  end
end
