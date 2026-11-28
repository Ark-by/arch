pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string panel: ""        // "", "launcher", "power", "shortcuts", "settings"
    property string wallpaper: ""

    // Превью обоев из сети — окно WallpaperPreview.qml
    property bool previewOpen: false
    property string previewId: ""
    property string previewThumb: ""
    property string previewRemote: ""
    property string previewResolution: ""
    property string previewLocal: ""
    property bool previewSaved: false

    function openPreview(id, thumb, remote, resolution) {
        previewId = id
        previewThumb = thumb
        previewRemote = remote
        previewResolution = resolution
        previewLocal = ""
        previewSaved = false
        previewOpen = true
    }

    function closePreview() {
        previewOpen = false
        previewId = ""
        previewThumb = ""
        previewRemote = ""
        previewResolution = ""
        previewLocal = ""
        previewSaved = false
    }

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
