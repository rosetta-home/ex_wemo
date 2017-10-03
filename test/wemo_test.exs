defmodule WemoTest do
  use ExUnit.Case
  doctest WeMo

  test "test actual Insight device on network" do
    WeMo.Client.start()
    WeMo.register()
    SSDP.Client.start()
    assert_receive {:device, %{device: %{device: %{device_type: 'urn:Belkin:device:insight:1'}}} = device}, 65_000
    device.pid |> WeMo.Device.Insight.on()
    assert_receive {:device, %{device: %{device: %{device_type: 'urn:Belkin:device:insight:1'}}, values: %{state: :on}} = device}, 10_000
    :timer.sleep(1000)
    #flush the mailbox
    receive do
      anything -> nil
    after
      0 -> nil
    end
    device.pid |> WeMo.Device.Insight.off()
    assert_receive {:device, %{device: %{device: %{device_type: 'urn:Belkin:device:insight:1'}}, values: %{state: :off}} = device}, 10_000
  end
end
