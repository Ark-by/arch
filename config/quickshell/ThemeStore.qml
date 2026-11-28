pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Только чтение списка палитр и применение через set-theme.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/themes"

    property var themes: []
    property string status: ""

    function reload() {
        lister.running = true
    }

    function base(t) {
        const f = t && t._file ? t._file : ""
        const n = f.substring(f.lastIndexOf("/") + 1)
        return n.toLowerCase().endsWith(".json") ? n.substring(0, n.length - 5) : ("" + (t && t.name ? t.name : "theme"))
    }

    function apply(b) {
        Quickshell.execDetached([root.home + "/.local/bin/set-theme", b])
        root.status = "Applied " + b
    }

    Process {
        id: lister
        command: ["sh", "-c",
            "for f in \"$1\"/*.json; do [ -f \"$f\" ] && jq -c --arg file \"$f\" '. + {file:$file}' \"$f\"; done",
            "ark", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const lines = ("" + this.text).split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const s = lines[i].trim()
                    if (s === "")
                        continue
                    try {
                        const t = JSON.parse(s)
                        if (t && t.name) {
                            if (t.file) { t._file = t.file; delete t.file }
                            out.push(t)
                        }
                    } catch (e) {
                        console.log("theme parse: " + e)
                    }
                }
                root.themes = out
            }
        }
    }

    Component.onCompleted: reload()
}