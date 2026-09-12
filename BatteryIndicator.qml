import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property int capacity: -1
    property string batteryst: "nan"
    property bool hasBattery: false
    property var battery: ({})

    readonly property int batFull: 100
    readonly property int batBreakpoint: 80
    readonly property real heightBreakpoint: 12.5
    readonly property int heightLow: 3
    readonly property int heightFull: 17

    readonly property int batNormalThreshold: 40
    readonly property int batWarningThreshold: 30

    readonly property real powerW: (root.battery.powerNow ?? 0) / 1e6
    readonly property real healthPct: root.battery.energyFullDesign
        ? (root.battery.energyFull / root.battery.energyFullDesign * 100)
        : 0
    readonly property bool showRemaining: root.batteryst === "Discharging"
        && (root.battery.powerNow ?? 0) > 0
        && (root.battery.energyNow ?? 0) > 0
    readonly property int minutesRemaining: root.showRemaining
        ? Math.round(root.battery.energyNow / root.battery.powerNow * 60)
        : 0

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

    visible: root.hasBattery

    Rectangle {
      height: root.getBatteryHeight(root.capacity)
      width: 8
      color: root.fillColor(root.capacity, root.batteryst)
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

    HoverHandler { id: hover }

    PopupWindow {
        id: tooltip
        visible: hover.hovered
        grabFocus: false
        color: "transparent"
        implicitWidth: content.implicitWidth + 16
        implicitHeight: content.implicitHeight + 16
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        Rectangle {
            anchors.fill: parent
            color: Theme.tooltip.bg
            border.color: Theme.tooltip.border
            border.width: 1
            radius: 4

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: root.capacity + "% · " + root.batteryst
                    color: Theme.tooltip.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Text {
                    visible: root.showRemaining
                    text: Math.floor(root.minutesRemaining / 60) + "h "
                        + (root.minutesRemaining % 60) + "m remaining"
                    color: Theme.tooltip.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    visible: root.healthPct > 0
                    text: "Health: " + root.healthPct.toFixed(0) + "%"
                    color: Theme.tooltip.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    visible: root.powerW > 0
                    text: root.powerW.toFixed(1) + " W"
                    color: Theme.tooltip.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    text: "Cycles: " + (root.battery.cycleCount ?? "—")
                    color: Theme.tooltip.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
