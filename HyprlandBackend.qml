import Quickshell
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: root

    property bool active: false

    readonly property int slots: 10

    readonly property var workspaces: {
        if (!active)
            return [];

        const live = Hyprland.workspaces.values;
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;

        const out = [];
        for (let i = 1; i <= slots; i++) {
            const ws = live.find(w => w.id === i) ?? null;
            out.push({
                key:      i,
                label:    i === 10 ? "0" : String(i),
                focused:  focusedId === i,
                occupied: ws !== null,
                output:   ws && ws.monitor ? ws.monitor.name : ""
            });
        }
        return out;
    }

    function focusWorkspace(key) {
        Hyprland.dispatch("workspace " + key);
    }
}
