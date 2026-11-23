pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property color bg: "#1e1e2e"
    property color surface: "#313244"
    property color fg: "#cdd6f4"
    property color accent: "#89b4fa"
    property color muted: "#6c7086"

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
