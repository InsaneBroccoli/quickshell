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

    readonly property int batFull: 100
    readonly property int batBreakpoint: 80
    readonly property real heightBreakpoint: 12.5
    readonly property int heightLow: 3
    readonly property int heightFull: 17

    readonly property int batNormalThreshold: 40
    readonly property int batWarningThreshold: 30

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

    function fillColor(cap, status) {
      switch(status) {
        case "Not charging":
          return Theme.bar.batNotCharging;
        case "Charging":
          return Theme.bar.batCharging;
      }

      if (cap < batNormalThreshold) {
        if (cap < batWarningThreshold) 
         return Theme.bar.batCritical;
        return Theme.bar.batWarning
      }
      return Theme.bar.batNormal;
    }

    function getBatteryHeight(cap) {
       let m;
       let b;

       if (cap <= batBreakpoint) {
         m = (heightBreakpoint - heightLow) / batBreakpoint;
         b = heightBreakpoint - m * batBreakpoint;
         return m * cap + b;
       }

       m = (heightFull - heightBreakpoint) / (batFull - batBreakpoint);
       b = heightFull - m * batFull;
       return m * cap + b;
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

            // Under niri each workspace belongs to an output, so
            // filter to this bar's screen. Hyprland's backend
            // reports "" for empty slots, which Workspaces lets
            // through — see the filter in Workspaces.qml.
            output: bar.modelData ? bar.modelData.name : ""
        }

        Separator {
            Layout.rightMargin: 2
        }

        // ToplevelManager is the wlr-foreign-toplevel protocol, which
        // both Hyprland and niri implement — no WM branch needed.
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

        Item {
          Layout.preferredWidth: 10
          Layout.preferredHeight: 18
          Layout.alignment: Qt.AlignVCenter
          visible: bar.hasBattery

          Rectangle {
            height: bar.getBatteryHeight(bar.capacity)
            width: 8
            color: bar.fillColor(bar.capacity, bar.batteryst)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            radius: 3
            topRightRadius: 1
            topLeftRadius: 1
          }

          Rectangle {
            anchors.fill: parent
            color: "transparent" 
            border.width: 1
            border.color: Theme.bar.batOutline
            radius: 3
          }

        }
    }
}
