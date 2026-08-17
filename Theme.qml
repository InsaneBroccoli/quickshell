pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: theme
    // ── Palette: Monokai Pro (default filter) ──
    readonly property color base:    "#2D2A2E"
    readonly property color baseDark:"#221F22"
    readonly property color surface: "#403E41"
    readonly property color text:    "#FCFCFA"
    readonly property color dim1:    "#C1C0C0"
    readonly property color dim2:    "#939293"
    readonly property color dim3:    "#727072"
    readonly property color dim4:    "#5B595C"

    readonly property color red:     "#FF6188"
    readonly property color orange:  "#FC9867"
    readonly property color yellow:  "#FFD866"
    readonly property color green:   "#A9DC76"
    readonly property color blue:    "#78DCE8"
    readonly property color purple:  "#AB9DF2"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14

    // ── Roles: named for what the color DOES ──
    readonly property QtObject bar: QtObject {
        readonly property color bg:             theme.base
        readonly property color separator:      theme.dim4
        readonly property color logo:           theme.blue

        readonly property color wsActive:       theme.green
        readonly property color wsOccupied:     theme.dim2
        readonly property color wsEmpty:        theme.dim4
        readonly property color wsUnderline:    theme.purple

        readonly property color windowTitle:    theme.purple
        readonly property color kernel:         theme.red
        readonly property color battery:        theme.green
        readonly property color clock:          theme.orange
        readonly property color batOutline:     theme.dim2
        readonly property color batNormal:      theme.green
        readonly property color batWarning:     theme.yellow
        readonly property color batCritical:    theme.red
        readonly property color batNotCharging: theme.purple
        readonly property color batCharging:    theme.blue
    }
}
