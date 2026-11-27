pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Чтение и правка ~/.config/hypr/keybinds.lua.
// Формат строк: bind(<key>, <dispatcher>, "<описание>") — правим только ключ,
// комментарий (-- ) и хвост (например, { locked = true }).
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/hypr/keybinds.lua"
    readonly property string pattern: "^(\\s*)(--\\s*)?bind\\((.+?),\\s*(.+),\\s*\"([^\"]*)\"\\)\\s*(.*)$"

    property var lines: []
    property var binds: []
    property string status: ""
    property bool dirty: false
    property bool loaded: false

    signal changed()

    function reload() {
        root.loaded = false
        reader.running = true
    }

    function parse() {
        const re = new RegExp(root.pattern)
        const out = []
        for (let i = 0; i < root.lines.length; i++) {
            const m = ("" + root.lines[i]).match(re)
            if (!m)
                continue
            out.push({
                index: i,
                enabled: m[2] === undefined,
                key: m[3].trim(),
                dispatch: m[4].trim(),
                desc: m[5]
            })
        }
        root.binds = out
    }

    function _rebuild(index, opts) {
        const re = new RegExp(root.pattern)
        const m = ("" + root.lines[index]).match(re)
        if (!m)
            return
        const indent = m[1]
        const comment = opts.enabled === undefined ? (m[2] || "") : (opts.enabled ? "" : "-- ")
        const key = opts.key === undefined ? m[3].trim() : opts.key
        const dispatch = m[4].trim()
        const desc = m[5]
        const tail = m[6] || ""
        root.lines[index] = indent + comment + "bind(" + key + ", " + dispatch + ', "' + desc + '")' + tail
        root.dirty = true
    }

    function setKey(index, key) {
        root._rebuild(index, { key: key })
        root.parse()
    }

    function setEnabled(index, enabled) {
        root._rebuild(index, { enabled: enabled })
        root.parse()
    }

    function remove(index) {
        const copy = root.lines.slice()
        copy[index] = ""
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function add(key, dispatch, desc) {
        const copy = root.lines.slice()
        copy.push("bind(" + key + ", " + dispatch + ', "' + desc + '")')
        root.lines = copy
        root.parse()
        root.dirty = true
    }

    function save() {
        if (!root.loaded) {
            root.status = "still loading — try Save again in a second"
            return
        }
        const text = root.lines.filter(l => l !== "").join("\n") + "\n"
        writer.payload = text
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = ("" + this.text).replace(/\s*$/, "")
                root.lines = text.split("\n")
                root.parse()
                root.loaded = true
                root.dirty = false
                root.status = "loaded " + root.binds.length + " binds"
                root.changed()
            }
        }
    }

    Process {
        id: writer
        property string payload: ""
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, root.path]
        onExited: (code, status) => {
            if (code !== 0) {
                root.status = "write failed (" + code + ")"
                return
            }
            root.dirty = false
            root.status = "saved " + root.binds.length + " binds"
            reloader.running = true
        }
    }

    Process {
        id: reloader
        command: ["hyprctl", "reload"]
    }

    Component.onCompleted: reload()
}