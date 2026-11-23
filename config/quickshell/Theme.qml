pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property color bg: "#1a1b26"
    property color surface: "#292e42"
    property color fg: "#c0caf5"
    property color accent: "#7aa2f7"
    property color muted: "#565f89"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = JSON.parse(text())
            root.bg = t.bg; root.surface = t.surface; root.fg = t.fg
            root.accent = t.accent; root.muted = t.muted
        }
    }
}
