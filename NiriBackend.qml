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

    // ── the contract ──────────────────────────────────────────
    readonly property var workspaces: rawWorkspaces
        .slice()                          // never sort in place
        .sort((a, b) => a.output === b.output
                        ? a.idx - b.idx
                        : String(a.output).localeCompare(String(b.output)))
        .map(ws => ({
            // `key` is opaque to the bar, so we store what niri's
            // CLI actually accepts as a workspace reference.
            key:      ws.name ? ws.name : ws.idx,
            label:    ws.name ? ws.name : String(ws.idx),
            focused:  ws.is_focused === true,
            // TODO(you): active_window_id is null for an empty
            // workspace, which is *almost* "occupied". It is wrong
            // for a workspace whose only window is on another
            // monitor's column. Track WindowsChanged /
            // WindowOpenedOrChanged / WindowClosed and count
            // windows per workspace_id if you want this exact.
            occupied: ws.active_window_id !== null && ws.active_window_id !== undefined,
            output:   ws.output ?? ""
        }))

    function focusWorkspace(key) {
        // TODO(you): this goes through the CLI, which resolves a
        // bare number as a *per-output* index — ambiguous once you
        // have two monitors. The correct fix is to write straight
        // to $NIRI_SOCKET, which takes a workspace id:
        //
        //   {"Action":{"FocusWorkspace":{"reference":{"Id":<ws.id>}}}}\n
        //
        // Quickshell.Io.Socket can do that. Try it once the rest
        // works; then `key` becomes ws.id and the mapping above
        // gets simpler, not harder.
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(key)]);
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

        }
        // TODO(you): three more events are worth handling, in this
        // order of usefulness. Each is a few lines and follows the
        // rebuild-the-array pattern above:
        //
        //   WorkspaceActiveWindowChanged {workspace_id, active_window_id}
        //       -> keeps `occupied` honest as you open/close windows
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
