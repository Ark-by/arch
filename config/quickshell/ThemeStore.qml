pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Чтение/запись палитр в ~/.config/themes/*.json и применение через set-theme.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/themes"
    readonly property string defaultTheme: "tokyonight"

    // [{ name, bg, surface, fg, accent, muted, ansi:[...], ..., _file }]
    property var themes: []
    property bool loaded: false
    property string lastError: ""
    property string selected: ""

    signal changed()

    readonly property var baseKeys: ["bg", "surface", "fg", "accent", "muted"]
    readonly property var semanticKeys: [
        "error", "warning", "success", "info", "border", "border_dark",
        "highlight", "elevated", "bg2", "bg3", "muted2", "orange", "teal",
        "type", "operator", "cyan_dark"
    ]

    function reload() {
        lister.running = true
    }

    function _parseLines(text) {
        const out = []
        const lines = ("" + text).split("\n")
        for (let i = 0; i < lines.length; i++) {
            const s = lines[i].trim()
            if (s === "")
                continue
            try {
                const t = JSON.parse(s)
                if (t && t.name) {
                    if (t.file) {
                        t._file = t.file
                        delete t.file
                    }
                    out.push(t)
                }
            } catch (e) {
                console.log("theme parse: " + e)
            }
        }
        return out
    }

    function _base(t) {
        const f = t._file || ""
        const n = f.substring(f.lastIndexOf("/") + 1)
        return n.toLowerCase().endsWith(".json") ? n.substring(0, n.length - 5) : ("" + (t.name || "theme"))
    }

    function fileName(t) {
        return root._base(t) + ".json"
    }

    function activeBase() {
        return Settings.get("theme.name", root.defaultTheme)
    }

    function find(base) {
        for (let i = 0; i < root.themes.length; i++)
            if (root._base(root.themes[i]) === base)
                return root.themes[i]
        return null
    }

    function _payload(obj) {
        const c = JSON.parse(JSON.stringify(obj))
        delete c._file
        return JSON.stringify(c, null, 2) + "\n"
    }

    function save(obj) {
        writer.payload = root._payload(obj)
        writer.target = root.dir + "/" + root.fileName(obj)
        writer.running = true
    }

    function duplicate(obj, newName) {
        const clean = ("" + newName).trim()
        if (clean === "")
            return false
        const slug = clean.toLowerCase().replace(/[^a-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "")
        if (slug === "" || root.find(slug) !== null)
            return false
        const copy = JSON.parse(JSON.stringify(obj))
        delete copy._file
        copy.name = clean
        copy._file = root.dir + "/" + slug + ".json"
        writer.payload = root._payload(copy)
        writer.target = copy._file
        writer.running = true
        return true
    }

    function remove(obj) {
        remover.target = obj._file
        remover.running = true
    }

    // Применить палитру: set-theme + запомнить имя в настройках
    function apply(base) {
        Settings.set("theme.name", base)
        Settings.apply()
        Quickshell.execDetached([root.home + "/.local/bin/set-theme", base])
    }

    Process {
        id: lister
        command: ["sh", "-c",
            "for f in \"$1\"/*.json; do [ -f \"$f\" ] && jq -c --arg file \"$f\" '. + {file:$file}' \"$f\"; done",
            "ark", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.themes = root._parseLines(this.text)
                root.loaded = true
                root.changed()
            }
        }
    }

    Process {
        id: writer
        property string payload: ""
        property string target: ""
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, writer.target]
        onExited: (code, status) => {
            if (code === 0) {
                root.lastError = ""
                root.reload()
            } else {
                root.lastError = "write failed (" + code + ")"
            }
        }
    }

    Process {
        id: remover
        property string target: ""
        command: ["rm", "-f", remover.target]
        onExited: (code, status) => root.reload()
    }

    Component.onCompleted: reload()
}