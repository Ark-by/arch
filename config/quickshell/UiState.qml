pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string panel: ""        // "", "launcher", "power", "shortcuts", "settings"
    property string wallpaper: ""
    readonly property string home: Quickshell.env("HOME")

    function toggle(name) { panel = (panel === name) ? "" : name }

    function setWallpaper(path) {
        wallpaper = path
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "sh",
            path, home + "/.config/quickshell/wallpaper.txt"])
    }

    FileView {
        path: root.home + "/.config/quickshell/wallpaper.txt"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }
}
