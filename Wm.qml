pragma Singleton

import Quickshell
import QtQuick

// Thin facade over the compositor backend. Only niri exists now; the
// indirection stays so widgets keep talking to `Wm.workspaces` and
// `Wm.focusWorkspace` rather than to a backend directly.
Singleton {
    id: root

    // Quickshell.env is a plain function, not a notifying property:
    // `active` is evaluated once at startup. niri-session exports
    // NIRI_SOCKET into the user manager, so this is set for the service.
    readonly property NiriBackend backend: NiriBackend {
        active: !!Quickshell.env("NIRI_SOCKET")
    }

    readonly property var workspaces: backend.workspaces

    function focusWorkspace(key) {
        backend.focusWorkspace(key);
    }

    Component.onCompleted: {
        if (!backend.active)
            console.warn("Wm: NIRI_SOCKET is not set; workspace list will stay empty");
    }
}
