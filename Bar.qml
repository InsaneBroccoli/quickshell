import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts


PanelWindow {
    id: bar

    property var modelData
    screen: modelData

    property string kernelVersion: "Linux"
    property int capacity: -1
    property string batteryst: "nan"

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

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            spacing: 0
            Repeater {
                model: 10

                Item {
                    Layout.preferredWidth: 16
                    Layout.fillHeight: true

                    property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    property bool isOccupied: workspace !== null

                    Text {
                        text: (index + 1) === 10 ? "0" : index + 1
                        color: parent.isActive ? Theme.bar.wsActive
                             : parent.isOccupied ? Theme.bar.wsOccupied
                             : Theme.bar.wsEmpty
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 8
                        color: parent.isActive ? Theme.bar.wsUnderline : "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }
        }

        Separator {
            Layout.rightMargin: 2
        }

        BarText {
            text: Hyprland.activeToplevel?.title ?? ""
            color: Theme.bar.windowTitle
            Layout.fillWidth: true
        }

        BarText {
            text: kernelVersion
            color: Theme.bar.kernel
        }

        Separator {
        }

        BarText {
            text: capacity + "%"
            color: Theme.bar.battery
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

          Rectangle {
            height: getBatteryHeight(capacity)
            width: 8
            color: fillColor(capacity, batteryst)
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
