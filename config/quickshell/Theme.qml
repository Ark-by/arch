pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Единственный потребитель палитры в QML.
// Значения по умолчанию — Tokyo Night; при старте подменяются из
// ~/.config/quickshell/theme.json (его генерирует set-theme).
Singleton {
    id: root

    // базовые
    property color bg: "#1a1b26"
    property color surface: "#292e42"
    property color fg: "#c0caf5"
    property color accent: "#7aa2f7"
    property color muted: "#565f89"

    // семантика
    property color error: "#f7768e"
    property color warning: "#e0af68"
    property color success: "#9ece6a"
    property color info: "#7dcfff"
    property color border: "#414868"
    property color muted2: "#6a7196"

    // производные
    property color elevated: "#14141b"
    property color bg2: "#1e202e"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let t
            try { t = JSON.parse(text()) } catch (e) { console.log("theme.json: " + e); return }

            // сначала семантика из ansi — работает с любой темой
            if (t.ansi && t.ansi.length >= 9) {
                root.error   = t.ansi[1]
                root.success = t.ansi[2]
                root.warning = t.ansi[3]
                root.info    = t.ansi[6]
                root.border  = t.ansi[8]
            }
            // затем явные ключи палитры (перекрывают ansi)
            if (t.bg)        root.bg = t.bg
            if (t.surface)   root.surface = t.surface
            if (t.fg)        root.fg = t.fg
            if (t.accent)    root.accent = t.accent
            if (t.muted)     root.muted = t.muted
            if (t.error)     root.error = t.error
            if (t.warning)   root.warning = t.warning
            if (t.success)   root.success = t.success
            if (t.info)      root.info = t.info
            if (t.border)    root.border = t.border
            if (t.muted2)    root.muted2 = t.muted2
            if (t.elevated)  root.elevated = t.elevated
            if (t.bg2)       root.bg2 = t.bg2
        }
    }
}