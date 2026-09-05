import Quickshell
import Quickshell.Io
import QtQuick

// ─────────────────────────────────────────────────────────────
// niri backend.
//
// Quickshell ships no Quickshell.Niri module, so this talks to
// niri's own IPC. `niri msg --json event-stream` prints one JSON
// object per line: first a full snapshot of the state, then
// deltas. Never poll — if you find yourself calling
// `niri msg workspaces` on a Timer, you have taken a wrong turn.
//
// Read one line of the raw stream before you touch this file:
//   niri msg --json event-stream | head -3 | jq
// ─────────────────────────────────────────────────────────────
QtObject {
    id: root

    property bool active: false

    // Raw niri Workspace objects, exactly as they come off the
    // wire:  { id, idx, name, output, is_urgent, is_active,
    //          is_focused, active_window_id }
    // Kept raw on purpose — translate at the edge (below), so the
    // day niri adds a field you only touch the mapping.
    property var rawWorkspaces: []

    // Raw niri Window objects, same treatment. Only `workspace_id`
    // is load-bearing here — it drives `occupied` — but the rest
    // rides along for whatever the bar wants next (urgency, counts).
    property var rawWindows: []

    // niri sends WindowsChanged one callback *after* the first
    // WorkspacesChanged, so for a frame `rawWindows` is empty while
    // `rawWorkspaces` is not. Until it lands, fall back to the
    // snapshot's own `active_window_id` (fresh at that instant) so
    // occupied workspaces don't flash the "empty" colour on startup.
    property bool windowsReady: false

    // "does a raw workspace hold a window?" — the single source of
    // truth for both the visibility filter and the `occupied` field.
    // Window-list derived, NOT ws.active_window_id: that field only
    // refreshes on a WorkspacesChanged snapshot, which barely fires
    // once the workspace set is fixed (persistent workspaces in
    // workspaces.kdl), so it rots to its startup value. The
    // active_window_id branch is the startup-only bridge described
    // at `windowsReady`. Called inside the `workspaces` binding, so
    // its property reads register as dependencies — safe.
    function occupied(ws) {
        return root.windowsReady
            ? root.rawWindows.some(w => w.workspace_id === ws.id)
            : (ws.active_window_id !== null && ws.active_window_id !== undefined);
    }

    // ── the contract ──────────────────────────────────────────
    readonly property var workspaces: rawWorkspaces
        .slice()                          // never sort in place
        .sort((a, b) => a.output === b.output
                        ? a.idx - b.idx
                        : String(a.output).localeCompare(String(b.output)))
        // niri keeps one trailing *unnamed* empty workspace per
        // output as scratch space. A persistent workspace always has
        // a name (workspaces.kdl); an unnamed one only earns a chip
        // while it is focused or holds a window. Without this the bar
        // shows a stray "10" (or "11", once "0" is added) chip.
        .filter(ws => !!ws.name || ws.is_focused === true || root.occupied(ws))
        .map(ws => ({
            // niri's socket resolves {"reference":{"Id":…}} against
            // the global workspace id, not the per-output idx.
            key:      ws.id,
            label:    ws.name ? ws.name : String(ws.idx),
            focused:  ws.is_focused === true,
            occupied: root.occupied(ws),
            output:   ws.output ?? ""
        }))

    // ── sending actions ───────────────────────────────────────
    // Won't redial if the connection dies — restart quickshell if
    // that ever happens. Not worth building reconnect logic for.
    // `connected` tracks desired state, not an established link, so
    // a click fired in the first moments after `active` flips true
    // (before the async connect lands) is dropped with a warning.
    // Not worth a pending-write queue — nobody clicks that fast.
    property Socket actionSocket: Socket {
        path: Quickshell.env("NIRI_SOCKET")
        connected: root.active
        onError: err => console.warn("niri: action socket error:", err)
        parser: SplitParser {
            onRead: line => {
                let reply;
                try {
                    reply = JSON.parse(line);
                } catch (e) {
                    console.warn("niri: unparseable action reply:", line);
                    return;
                }
                if (reply.Err)
                    console.warn("niri: action failed:", reply.Err);
            }
        }
    }

    function focusWorkspace(key) {
        if (!actionSocket.connected) {
            console.warn("niri: action socket not connected, dropping focus request");
            return;
        }
        actionSocket.write(JSON.stringify({
            Action: { FocusWorkspace: { reference: { Id: key } } }
        }) + "\n");
        actionSocket.flush();
    }

    // ── the event stream ──────────────────────────────────────
    property Process ipc: Process {
        running: root.active
        command: ["niri", "msg", "--json", "event-stream"]

        // SplitParser splits on "\n" by default: one call per event.
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
    }

    function handleEvent(line) {
        if (!line)
            return;

        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            console.warn("niri: unparseable event line:", line);
            return;
        }

        // niri serialises its Event enum as a single-key object,
        // e.g. {"WorkspaceActivated":{"id":3,"focused":true}}.
        if (ev.WorkspacesChanged) {
            // Full snapshot. Sent once at connect and again on any
            // structural change (workspace added/removed/moved).
            root.rawWorkspaces = ev.WorkspacesChanged.workspaces;

        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const focused = ev.WorkspaceActivated.focused;

            const target = root.rawWorkspaces.find(w => w.id === id);
            if (!target)
                return;

            // QML only re-evaluates `workspaces` if the array
            // *identity* changes — mutating an element in place is
            // silently invisible. So rebuild.
            root.rawWorkspaces = root.rawWorkspaces.map(w => Object.assign({}, w, {
                // one active workspace per output
                is_active:  w.output === target.output ? (w.id === id) : w.is_active,
                // one focused workspace globally
                is_focused: focused ? (w.id === id) : w.is_focused
            }));

        } else if (ev.WindowsChanged) {
            // Full window snapshot, sent once just after the first
            // WorkspacesChanged.
            root.rawWindows = ev.WindowsChanged.windows;
            root.windowsReady = true;

        } else if (ev.WindowOpenedOrChanged) {
            // Upsert by id. This fires on every title/focus/layout
            // change too, not just workspace moves. `occupied` (the
            // only consumer today) keys off workspace_id, so when
            // that is unchanged, refresh the stored object in place
            // and stop: mutating an element keeps the array identity,
            // so the `workspaces` binding does not re-run and the
            // bar's chip delegates are not rebuilt — but a later
            // consumer of e.g. is_urgent still sees current data.
            const win = ev.WindowOpenedOrChanged.window;
            const prev = root.rawWindows.find(w => w.id === win.id);
            if (prev && prev.workspace_id === win.workspace_id) {
                Object.assign(prev, win);
                return;
            }
            // workspace_id changed (or new window): rebuild so the
            // binding sees it. filter-then-concat, never push —
            // array identity must change.
            root.rawWindows = root.rawWindows
                .filter(w => w.id !== win.id)
                .concat([win]);

        } else if (ev.WindowClosed) {
            const id = ev.WindowClosed.id;
            root.rawWindows = root.rawWindows.filter(w => w.id !== id);

        }
        // TODO(you): two more events are worth handling, in this
        // order of usefulness. Each is a few lines and follows the
        // rebuild-the-array pattern above:
        //
        //   WorkspaceUrgencyChanged      {id, urgent}
        //       -> add `urgent` to the contract in Wm.qml and a
        //          Theme.bar.wsUrgent colour, then use it in
        //          Workspaces.qml
        //   ConfigLoaded                 {failed}
        //       -> flash something in the bar when your niri config
        //          fails to reload; you will want this the first
        //          week you use niri.
        //
        // Unhandled events are simply ignored, so add them one at a
        // time and check with:  qs log  (or watch stderr).
    }
}
