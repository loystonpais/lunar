{
  den,
  lunar,
  inputs,
  ...
}: {
  den.hosts.x86_64-linux = {
    roglaptop = {
      cgroupDevices = [
        "/dev/input/by-id/usb-Logitech_Gaming_Mouse_G402_497B57573447-event-mouse"
        "/dev/input/by-id/usb-SINO_WEALTH_Gaming_KB-event-kbd"
      ];

      users = {
        loystonpais = {};
      };
    };

    nixacle = {
      users = {
        loystonpais = {};
      };
    };

    diviner = {
      users = {
        loystonpais = {};
      };
    };
  };

  den.hosts.aarch64-linux = {
    vili = {
      users = {
        loystonpais = {};
      };
    };
  };
}
