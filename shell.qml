import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // System info properties
    property string kernelVersion: "Linux"
    property int capacity: 0

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }
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

    // Slow timer for system stats
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: {
            batFile.reload()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30
            color: Theme.bar.bg

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bar.bg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item { Layout.preferredWidth: 8 }

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

                    Item { Layout.preferredWidth: 8 }

                    Repeater {
                        model: 10

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.fillHeight: true
                            color: "transparent"

                            property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                            property bool hasWindows: workspace !== null

                            Text {
                                text: (index + 1) === 10 ? "0" : index + 1
                                color: parent.isActive ? Theme.bar.wsActive
                                     : parent.hasWindows ? Theme.bar.wsOccupied
                                     : Theme.bar.wsEmpty
                                font.pixelSize: Theme.fontSize
                                font.family: Theme.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Rectangle {
                                width: 20
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

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 2
                        color: Theme.bar.separator
                    }

                    Text {
                        text: Hyprland.activeToplevel?.title ?? ""
                        color: Theme.bar.windowTitle
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        text: kernelVersion
                        color: Theme.bar.kernel
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: Theme.bar.separator
                    }

                    Text {
                        text: capacity + "%"
                        color: Theme.bar.battery
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: Theme.bar.separator
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "ddd, MMM dd - HH:mm")
                        color: Theme.bar.clock
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8

                    }

                    Item { Layout.preferredWidth: 8 }
                }
            }
        }
    }
}
