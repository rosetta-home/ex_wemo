# WeMo

Discover, monitor and control [Belkin WeMo](http://www.belkin.com/us/Products/home-automation/c/wemo-home-automation/) devices on your local network

## Supported Devices
  * LightSwitch
  * Insight
  * Switch
  * Coffee Maker
  * More coming soon.
    * Or feel free to add your favorite.
    * Feel free to reach out if you need some help.

## Installation

    1. git clone https://github.com/NationalAssociationOfRealtors/wemo.git
    2. cd wemo
    3. mix do deps.get, deps.compile
    4. iex -S mix
    5. WeMo.Client.start(host_ip \\ nil)
    6. WeMo.register()
    7. SSDP.Client.start()

## Usage

`WeMo.Client.start` registers the WeMo library with the `SSDP.Registry`. You can pass `WeMo.Client.start` your IP address, or it will attempt to ascertain it by iterating over your network interfaces and using the first non-local ipv4 address it finds. The IP is for setting the `CALLBACK` url for the `SOAP` actions. Calling `WeMo.Client.start` allows you to wait for the network to be up, especially helpful when dealing with [Nerves](http://nerves-project.org) systems.

The WeMo library runs a small cowboy server on port `8083` by default, this is overridable via `:wemo, :http_port`, for receiving subscription events from the devices. You should see some success and error messages if you ran the interactive terminal session in the installation section.

Calling `WeMo.register()`, registers your process with the `WeMo.Registry`. All events and action results are published over this registry. You can handle events using `handle_info({:device, device})` in the process that called `WeMo.register()`. Where device is the device state shown below.

Once everything is configured we start the `SSDP.Client`, again this allows us to wait until the network is up before looking for devices.

## Events and Action Results

The events and action results are the same thing, just the most up-to-date state object from the device. They are both broadcast over the registry in the form `{:device, device}` where the device is a State object for the given device type. Each device type `Insight, LightSwitch, etc` writes it's unique state to the `values` key.

### Insight values
```elixir
%WeMo.Device.Insight.Values{
  average_power: 0,
  current_power: 0,
  energy_today: 630892,
  energy_total: 1128564767,
  last_changed_at: 1507047806,
  last_on_for: 3,
  on_today: 231,
  on_total: 1036198,
  standby_limit: 0,
  state: :off,
  timespan: 70729
}
```

### Insight Device State

The full device state also includes the SSDP device state `device`, subscription registration ids `sids`, `host_ip` and the `pid` of the device process.
```elixir
{:device,
  %WeMo.Device.Insight.State{
    device: %{
      device: %{
        device_type: 'urn:Belkin:device:insight:1',
        friendly_name: 'Home Lab Insight',
        icon_list: [%{depth: '100', height: '100', mime_type: 'jpg', url: 'icon.jpg', width: '100'}],
        manufacturer: 'Belkin International Inc.',
        manufacturer_url: 'http://www.belkin.com',
        model_description: 'Belkin Insight 1.0', model_name: 'Insight',
        model_number: '1.0', model_url: 'http://www.belkin.com/plugin/',
        presentation_url: '/pluginpres.html', serial_number: nil,
        service_list: [%{control_url: '/upnp/control/WiFiSetup1',
           event_sub_url: '/upnp/event/WiFiSetup1', scpd_url: '/setupservice.xml',
           service_id: 'urn:Belkin:serviceId:WiFiSetup1',
           service_type: 'urn:Belkin:service:WiFiSetup:1'},
         %{control_url: '/upnp/control/timesync1',
           event_sub_url: '/upnp/event/timesync1',
           scpd_url: '/timesyncservice.xml',
           service_id: 'urn:Belkin:serviceId:timesync1',
           service_type: 'urn:Belkin:service:timesync:1'},
         %{control_url: '/upnp/control/basicevent1',
           event_sub_url: '/upnp/event/basicevent1',
           scpd_url: '/eventservice.xml',
           service_id: 'urn:Belkin:serviceId:basicevent1',
           service_type: 'urn:Belkin:service:basicevent:1'},
         %{control_url: '/upnp/control/firmwareupdate1',
           event_sub_url: '/upnp/event/firmwareupdate1',
           scpd_url: '/firmwareupdate.xml',
           service_id: 'urn:Belkin:serviceId:firmwareupdate1',
           service_type: 'urn:Belkin:service:firmwareupdate:1'},
         %{control_url: '/upnp/control/rules1',
           event_sub_url: '/upnp/event/rules1', scpd_url: '/rulesservice.xml',
           service_id: 'urn:Belkin:serviceId:rules1',
           service_type: 'urn:Belkin:service:rules:1'},
         %{control_url: '/upnp/control/metainfo1',
           event_sub_url: '/upnp/event/metainfo1',
           scpd_url: '/metainfoservice.xml',
           service_id: 'urn:Belkin:serviceId:metainfo1',
           service_type: 'urn:Belkin:service:metainfo:1'},
         %{control_url: '/upnp/control/remoteaccess1',
           event_sub_url: '/upnp/event/remoteaccess1',
           scpd_url: '/remoteaccess.xml',
           service_id: 'urn:Belkin:serviceId:remoteaccess1',
           service_type: 'urn:Belkin:service:remoteaccess:1'},
         %{control_url: '/upnp/control/deviceinfo1',
           event_sub_url: '/upnp/event/deviceinfo1',
           scpd_url: '/deviceinfoservice.xml',
           service_id: 'urn:Belkin:serviceId:deviceinfo1',
           service_type: 'urn:Belkin:service:deviceinfo:1'},
         %{control_url: '/upnp/control/insight1',
           event_sub_url: '/upnp/event/insight1', scpd_url: '/insightservice.xml',
           service_id: 'urn:Belkin:serviceId:insight1',
           service_type: 'urn:Belkin:service:insight:1'},
         %{control_url: '/upnp/control/smartsetup1',
           event_sub_url: '/upnp/event/smartsetup1', scpd_url: '/smartsetup.xml',
           service_id: 'urn:Belkin:serviceId:smartsetup1',
           service_type: 'urn:Belkin:service:smartsetup:1'},
         %{control_url: '/upnp/control/manufacture1',
           event_sub_url: '/upnp/event/manufacture1',
           scpd_url: '/manufacture.xml',
           service_id: 'urn:Belkin:serviceId:manufacture1',
           service_type: 'urn:Belkin:service:manufacture:1'}
        ],
        udn: 'uuid:Insight-1_0-221350K12000B5',
        upc: nil
      },
      uri: %URI{
        authority: "192.168.10.19:49153",
        fragment: nil,
        host: "192.168.10.19",
        path: "/setup.xml",
        port: 49153,
        query: nil,
        scheme: "http",
        userinfo: nil
      },
      url: nil,
      version: %{major: '1', minor: '0'}
    },
    host_ip: {192, 168, 10, 5},
    pid: :"uuid:Insight-1_0-221350K12000B5",
    sids: ["uuid:33db5c96-1dd2-11b2-a2a3-c9a4beb5df50",
      "uuid:33dd9164-1dd2-11b2-a2a3-c9a4beb5df50",
      "uuid:33e04242-1dd2-11b2-a2a3-c9a4beb5df50",
      "uuid:33e1ef3e-1dd2-11b2-a2a3-c9a4beb5df50",
      "uuid:347f752e-1dd2-11b2-a2a3-c9a4beb5df50",
      "uuid:3481cbc6-1dd2-11b2-a2a3-c9a4beb5df50"
    ],
    values: %WeMo.Device.Insight.Values{
      average_power: 0,
      current_power: 0,
      energy_today: 630892,
      energy_total: 1128564767,
      last_changed_at: 1507047806,
      last_on_for: 3,
      on_today: 231,
      on_total: 1036198,
      standby_limit: 0,
      state: :off,
      timespan: 70729
    }
  }
}
```

Here is the simple test to check an actual WeMo Insight on your network.

```elixir    
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
    :timer.sleep(800)
    device.pid |> WeMo.Device.Insight.off()
    assert_receive {:device, %{device: %{device: %{device_type: 'urn:Belkin:device:insight:1'}}, values: %{state: :off}} = device}, 10_000
  end
end
```

If you have more than one Insight on your network, you may want to pattern match on `{:device, %{device: %{device: %{udn: device_udn}}}}`
