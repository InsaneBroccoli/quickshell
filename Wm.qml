pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string compositor:
          Quickshell.env("NIRI_SOCKET") ? "niri"
        : Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland"
        : "unknown"

    readonly property HyprlandBackend hyprland: HyprlandBackend {
        active: root.compositor === "hyprland"
    }

    readonly property NiriBackend niri: NiriBackend {
        active: root.compositor === "niri"
    }

    readonly property var backend:
          compositor === "hyprland" ? hyprland
        : compositor === "niri"     ? niri
        : null

    readonly property var workspaces: backend ? backend.workspaces : []

    function focusWorkspace(key) {
        if (backend)
            backend.focusWorkspace(key);
    }
}
