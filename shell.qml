import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    // System info properties
    property string kernelVersion: "Linux"
    property int capacity: -1
    property string batteryStatus: "nan"
    property bool hasBattery: false
    property var battery: ({})

    // Kernel version
    FileView {
        id: kernelFile
        path: "/proc/sys/kernel/osrelease"

        onLoaded: {
          root.kernelVersion = kernelFile.text().trim()
        }
    }

    // Battery capacity
    FileView {
        id: batFile
        path: "/sys/class/power_supply/BAT0/capacity"

        onLoaded: {
          root.capacity = parseInt(batFile.text())
        }
    }

    FileView {
      id: batStatus
      path: "/sys/class/power_supply/BAT0/status"

      onLoaded: {
        root.batteryStatus = batStatus.text().trim()
      }
    }

    FileView {
      id: batUevent
      path: "/sys/class/power_supply/BAT0/uevent"

      onLoaded: {
        root.battery = root.parseUevent(batUevent.text())
      }
    }

    function parseUevent(text) {
      const fields = {};
      for (const line of text.split("\n")) {
        const idx = line.indexOf("=");
        if (idx === -1) continue;
        const key = line.slice(0, idx).replace("POWER_SUPPLY_", "");
        fields[key] = line.slice(idx + 1);
      }

      // parseInt returns NaN for absent keys, which is not nullish and so
      // slips past every ?? guard downstream. Batteries reporting the
      // charge family (CHARGE_NOW/CURRENT_NOW) lack these keys entirely.
      const num = key => {
        const n = parseInt(fields[key]);
        return Number.isFinite(n) ? n : undefined;
      };

      return {
        cycleCount: num("CYCLE_COUNT"),
        powerNow: num("POWER_NOW"),
        energyNow: num("ENERGY_NOW"),
        energyFull: num("ENERGY_FULL"),
        energyFullDesign: num("ENERGY_FULL_DESIGN"),
        voltageNow: num("VOLTAGE_NOW"),
        modelName: fields.MODEL_NAME,
        manufacturer: fields.MANUFACTURER
      };
    }

    FileView {
      id: batteryAvailable
      path: Quickshell.env("HOME") + ("/.config/quickshell/host-facts.json")

      onLoaded: {
        root.hasBattery = JSON.parse(batteryAvailable.text()).hasBattery
      }

    }

    // Slow timer for system stats
    Timer {
        interval: 2000
        running: root.hasBattery
        repeat: true
        onTriggered: {
            batFile.reload()
            batStatus.reload()
            batUevent.reload()
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
          capacity: root.capacity
          kernelVersion: root.kernelVersion
          batteryst: root.batteryStatus
          hasBattery: root.hasBattery
          battery: root.battery
        }
    }
}
