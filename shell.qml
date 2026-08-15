import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    // System info properties
    property string kernelVersion: "Linux"
    property int capacity: -1
    property string batteryst: "nan"

    // Kernel version
    FileView {
        id: kernelFile
        path: "/proc/sys/kernel/osrelease"

        onLoaded: {
          kernelVersion = kernelFile.text().trim()
        }
    }

    // Battery capacity
    FileView {
        id: batFile
        path: "/sys/class/power_supply/BAT0/capacity"

        onLoaded: {
          capacity = parseInt(batFile.text())
        }
    }

    FileView {
      id: batStatus
      path: "/sys/class/power_supply/BAT0/status"

      onLoaded: {
        batteryStatus = batStatus.text().trim()
      }
    }

    // Slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            batFile.reload()
            batStatus.reload()
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
          capacity: root.capacity
          kernelVersion: root.kernelVersion
          batteryst: root.batteryst
        }
    }
}
