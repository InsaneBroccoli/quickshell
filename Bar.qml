import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    property var modelData
    screen: modelData

    property string kernelVersion: "Linux"
    property int capacity: -1
    property string batteryst: "nan"
    property bool hasBattery: false
    property var battery: ({})

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 30
    color: Theme.bar.bg

    component Separator: Rectangle {
      Layout.preferredWidth: 2
      Layout.preferredHeight: 18
      Layout.alignment: Qt.AlignVCenter
      color: Theme.bar.separator
      radius: 8
    }

    component BarText: Text {
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
      font.bold: true
      elide: Text.ElideRight
      Layout.alignment: Qt.AlignVCenter
      maximumLineCount: 1
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.bar.logo
                font.pixelSize: 24
                font.family: Theme.fontFamily
                font.bold: true
            }
        }

        Workspaces {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true

            // Each niri workspace belongs to an output, so filter
            // to this bar's screen — see the filter in Workspaces.qml.
            output: bar.modelData ? bar.modelData.name : ""
        }

        Separator {
            Layout.rightMargin: 2
        }

        // ToplevelManager is the wlr-foreign-toplevel protocol, which
        // niri implements — no compositor-specific code needed.
        // Verify on a new compositor with:
        //   wayland-info | grep foreign_toplevel
        BarText {
            text: ToplevelManager.activeToplevel?.title ?? ""
            color: Theme.bar.windowTitle
            Layout.fillWidth: true
        }

        BarText {
            text: bar.kernelVersion
            color: Theme.bar.kernel
        }

        Separator {
        }

        BarText {
            text: Qt.formatDateTime(clock.date, "ddd, MMM dd - HH:mm")
            color: Theme.bar.clock
        }

        BatteryIndicator {
            Layout.preferredWidth: 10
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter
            capacity: bar.capacity
            batteryst: bar.batteryst
            hasBattery: bar.hasBattery
            battery: bar.battery
        }
    }
}
