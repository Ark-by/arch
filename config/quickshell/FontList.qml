pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Список установленных семейств шрифтов для выпадающих списков.
Singleton {
    id: root

    property var families: []
    property bool loaded: false

    function reload() {
        lister.running = true
    }

    Component.onCompleted: reload()

    Process {
        id: lister
        command: ["fc-list", ":", "family"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = ({})
                const out = []
                const lines = ("" + this.text).split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(",")
                    for (let j = 0; j < parts.length; j++) {
                        const name = parts[j].trim()
                        if (name === "" || seen[name])
                            continue
                        seen[name] = true
                        out.push(name)
                    }
                }
                out.sort((a, b) => a.localeCompare(b))
                root.families = out
                root.loaded = true
            }
        }
    }
}