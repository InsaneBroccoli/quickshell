import QtQuick
import QtQuick.Layouts

// The workspace indicator. Note what is *not* in this file: any
// mention of Hyprland or niri. It repeats over whatever Wm gives
// it, so a fixed 1..10 grid (Hyprland) and a growing dynamic list
// (niri) are the same widget.
RowLayout {
    id: root

    spacing: 0

    // Name of the screen this bar instance lives on. Empty = show
    // everything. niri reports a real output per workspace, so this
    // is what stops monitor 2's workspaces appearing on monitor 1.
    property string output: ""

    readonly property var items: root.output === ""
        ? Wm.workspaces
        : Wm.workspaces.filter(ws => ws.output === "" || ws.output === root.output)

    Repeater {
        model: root.items

        delegate: Item {
            id: chip

            required property var modelData

            Layout.preferredWidth: 16
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: chip.modelData.label
                color: chip.modelData.focused  ? Theme.bar.wsActive
                     : chip.modelData.occupied ? Theme.bar.wsOccupied
                     : Theme.bar.wsEmpty
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 3
                radius: 8
                color: chip.modelData.focused ? Theme.bar.wsUnderline : "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Wm.focusWorkspace(chip.modelData.key)
            }
        }
    }
}
