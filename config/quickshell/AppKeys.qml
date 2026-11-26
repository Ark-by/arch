pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды приложений: kitty (map) и cmus (bind) — строчный формат.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property var targets: [
        {
            id: "kitty",
            label: "kitty",
            verb: "map",
            path: home + "/.config/kitty/kitty.conf",
            re: "^(\\s*)(#\\s*)?map\\s+(\\S+)\\s+(.+)$"
        },
        {
            id: "cmus",
            label: "cmus",
            verb: "bind",
            path: home + "/.config/cmus/rc",
            re: "^(\\s*)(#\\s*)?bind\\s+(\\S+)\\s+(.+)$"
        }
    ]

    property string targetId: "kitty"
    property var lines: []
    property var entries: []
    property string status: ""
    property bool dirty: false

    signal changed()

    function target() {
        for (let i = 0; i < root.targets.length; i++)
            if (root.targets[i].id === root.targetId)
                return root.targets[i]
        return root.targets[0]
    }

    function reload() {
        reader.running = true
    }

    function parse() {
        const t = root.target()
        const re = new RegExp(t.re)
        const out = []
        for (let i = 0; i < root.lines.length; i++) {
            const m = ("" + root.lines[i]).match(re)
            if (!m)
                continue
            out.push({
                index: i,
                enabled: m[2] === undefined,
                key: m[3],
                action: m[4]
            })
        }
        root.entries = out
    }

    function _rebuild(index, opts) {
        const t = root.target()
        const re = new RegExp(t.re)
        const m = ("" + root.lines[index]).match(re)
        if (!m)
            return
        const indent = m[1]
        const comment = opts.enabled === undefined ? (m[2] || "") : (opts.enabled ? "" : "# ")
        const key = opts.key === undefined ? m[3] : opts.key
        const action = opts.action === undefined ? m[4] : opts.action
        root.lines[index] = indent + comment + t.verb + " " + key + " " + action
        root.dirty = true
    }

    function setKey(index, key) {
        root._rebuild(index, { key: key })
        root.parse()
    }

    function setAction(index, action) {
        root._rebuild(index, { action: action })
        root.parse()
    }

    function setEnabled(index, enabled) {
        root._rebuild(index, { enabled: enabled })
        root.parse()
    }

    function remove(index) {
        const copy = root.lines.slice()
        copy.splice(index, 1)
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function add(key, action) {
        const copy = root.lines.slice()
        copy.push(root.target().verb + " " + key + " " + action)
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function save() {
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
            if (code !== 0)
                root.status = "write failed (" + code + ")"
            else {
                root.dirty = false
                root.status = "saved " + root.entries.length + " binds"
                root.reload()
            }
        }
    }
}