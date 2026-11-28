pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Хранилище настроек страницы обоев: sourceUrl, apiKey, savedSources.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string path: home + "/.local/state/quickshell/settings.json"

    property var data: ({
        sourceUrl: "https://wallhaven.cc/api/v1/collections/lewdpatriot/935888",
        apiKey: "",
        savedSources: [
            "https://wallhaven.cc/api/v1/collections/lewdpatriot/935888",
            "https://wallhaven.cc/api/v1/search?sorting=toplist",
            "https://wallhaven.cc/hot"
        ]
    })
    property bool loaded: false
    property bool dirty: false

    signal changed()

    function reload() { reader.running = true }

    function get(key, fallback) {
        return (key in root.data) ? root.data[key] : fallback
    }

    function set(key, value) {
        const d = JSON.parse(JSON.stringify(root.data))
        d[key] = value
        root.data = d
        root.dirty = true
    }

    function apply() {
        writer.payload = JSON.stringify(root.data, null, 2) + "\n"
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = ("" + this.text).trim()
                if (raw !== "") {
                    try {
                        const parsed = JSON.parse(raw)
                        const d = JSON.parse(JSON.stringify(root.data))
                        for (const k in parsed)
                            d[k] = parsed[k]
                        root.data = d
                    } catch (e) {
                        console.log("settings.json: " + e)
                    }
                }
                root.loaded = true
                root.changed()
            }
        }
    }

    Process {
        id: writer
        property string payload: ""
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, root.path]
        onExited: (code, status) => {
            if (code === 0)
                root.dirty = false
        }
    }

    Component.onCompleted: reload()
}