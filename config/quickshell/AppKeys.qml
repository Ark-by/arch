pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды приложений.
// kitty: map <key> <action>
// cmus:  bind [-f] [context] <key> <command>
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property var cmusContexts: [
        "common", "browser", "library", "playlist", "queue", "filters", "settings"
    ]

    property string targetId: "kitty"
    property var lines: []
    property var entries: []
    property string status: ""
    property bool dirty: false
    property bool loaded: false
    property bool fileMissing: false

    signal changed()

    function target() {
        return root.targetId === "cmus"
            ? {
                id: "cmus",
                path: root.home + "/.config/cmus/rc",
                verb: "bind",
                hasContext: true
            }
            : {
                id: "kitty",
                path: root.home + "/.config/kitty/kitty.conf",
                verb: "map",
                hasContext: false
            }
    }

    readonly property var reCmus: /^(\s*)(#\s*)?bind\s+((?:-[a-zA-Z]+\s+)*)((?:common|browser|library|playlist|queue|filters|settings)\s+)?(\S+)\s+(.+)$/
    readonly property var reKitty: /^(\s*)(#\s*)?map\s+(\S+)\s+(.+)$/

    function reload() {
        root.loaded = false
        reader.running = true
    }

    function parse() {
        const out = []
        const isCmus = root.targetId === "cmus"
        for (let i = 0; i < root.lines.length; i++) {
            const line = "" + root.lines[i]
            if (isCmus) {
                const m = line.match(root.reCmus)
                if (!m)
                    continue
                out.push({
                    index: i,
                    enabled: m[2] === undefined,
                    flags: (m[3] || "").trim(),
                    context: (m[4] || "").trim(),
                    key: m[5],
                    action: m[6]
                })
            } else {
                const m = line.match(root.reKitty)
                if (!m)
                    continue
                out.push({
                    index: i,
                    enabled: m[2] === undefined,
                    flags: "",
                    context: "",
                    key: m[3],
                    action: m[4]
                })
            }
        }
        root.entries = out
    }

    function entryAt(lineIndex) {
        for (let i = 0; i < root.entries.length; i++)
            if (root.entries[i].index === lineIndex)
                return root.entries[i]
        return null
    }

    function _rebuild(lineIndex, opts) {
        const e = root.entryAt(lineIndex)
        if (!e)
            return
        const indent = (root.lines[lineIndex].match(/^\s*/) || [""])[0]
        const enabled = opts.enabled === undefined ? e.enabled : opts.enabled
        const flags = opts.flags === undefined ? e.flags : opts.flags
        const context = opts.context === undefined ? e.context : opts.context
        const key = opts.key === undefined ? e.key : opts.key
        const action = opts.action === undefined ? e.action : opts.action

        let line = indent + (enabled ? "" : "# ") + root.target().verb + " "
        if (root.target().hasContext) {
            if (flags !== "")
                line += flags + " "
            if (context !== "")
                line += context + " "
        }
        line += key + " " + action
        root.lines[lineIndex] = line
        root.dirty = true
    }

    function setKey(lineIndex, key) {
        root._rebuild(lineIndex, { key: key })
        root.parse()
    }

    function setAction(lineIndex, action) {
        root._rebuild(lineIndex, { action: action })
        root.parse()
    }

    function setContext(lineIndex, context) {
        root._rebuild(lineIndex, { context: context })
        root.parse()
    }

    function setEnabled(lineIndex, enabled) {
        root._rebuild(lineIndex, { enabled: enabled })
        root.parse()
    }

    function remove(lineIndex) {
        const copy = root.lines.slice()
        copy.splice(lineIndex, 1)
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function add(key, action, context, flags) {
        const copy = root.lines.slice()
        let line = root.target().verb + " "
        if (root.target().hasContext) {
            if (flags && flags !== "")
                line += flags + " "
            if (context && context !== "")
                line += context + " "
        }
        line += key + " " + action
        copy.push(line)
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function save() {
        if (!root.loaded) {
            root.status = "still loading — try Save again in a second"
            return
        }
        if (root.lines.length === 0 && !root.fileMissing) {
            root.status = "refusing to write an empty file"
            return
        }
        writer.payload = root.lines.filter(l => l !== "").join("\n") + "\n"
        writer.target = root.target().path
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.target().path]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = ("" + this.text).replace(/\s*$/, "")
                root.lines = text === "" ? [] : text.split("\n")
                root.parse()
                root.fileMissing = (text === "")
                root.loaded = true
                root.dirty = false
            }
        }
    }

    Process {
        id: writer
        property string payload: ""
        property string target: ""
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, writer.target]
        onExited: (code, status) => {
            if (code !== 0) {
                root.status = "write failed (" + code + ")"
                return
            }
            root.dirty = false
            root.status = "saved " + root.entries.length + " binds"
            root.reload()
        }
    }
}