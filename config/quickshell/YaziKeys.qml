pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды yazi как в Zed: единый редактируемый список.
// База — штатный пресет, поверх накладываются записи из ~/.config/yazi/keymap.toml.
// Save записывает весь список в файл (формат [mgr] keymap = [ ... ]).
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/yazi/keymap.toml"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/quickshell/defaults/yazi-keymap.toml"

    property var entries: []
    property var userIds: []
    property string status: ""
    property bool loaded: false
    property bool dirty: false

    readonly property var reInline: /^\s*\{\s*on\s*=\s*(.+?),\s*run\s*=\s*(.+?)(?:,\s*desc\s*=\s*"([^"]*)")?\s*\}\s*,?\s*$/

    function reload() {
        root.loaded = false
        root.entries = []
        defaultsReader.running = true
        reader.running = true
    }

    function _unquote(text) {
        let s = ("" + text).trim()
        if (s.length >= 2 && s.charAt(0) === '"' && s.charAt(s.length - 1) === '"')
            return s.slice(1, -1).replace(/\\"/g, '"')
        if (s.length >= 2 && s.charAt(0) === "'" && s.charAt(s.length - 1) === "'")
            return s.slice(1, -1)
        return s
    }

    function _keys(text) {
        const out = []
        const re = /"([^"]*)"/g
        let m
        while ((m = re.exec(text)) !== null)
            out.push(m[1])
        if (out.length === 0)
            out.push(root._unquote(text))
        return out
    }

    function _display(raw) {
        const s = ("" + raw).trim()
        return s.charAt(0) === "[" ? root._keys(s).join(" ") : root._unquote(s)
    }

    function _quote(value) {
        return '"' + ("" + value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + '"'
    }

    function _onToml(value) {
        const v = ("" + value).trim()
        if (v.indexOf(" ") >= 0) {
            const parts = v.split(/\s+/).filter(x => x !== "")
            return "[ " + parts.map(p => root._quote(p)).join(", ") + " ]"
        }
        return root._quote(v)
    }

    // Возвращает массив { on, run, desc } из любого из форматов
    function parseEntries(lines, onlyMgr) {
        const out = []
        let inMgr = !onlyMgr
        let inBlock = false
        for (let i = 0; i < lines.length; i++) {
            const t = ("" + lines[i]).trim()
            if (t === "[mgr]") { inMgr = true; continue }
            if (t.charAt(0) === "[" && t !== "[mgr]")
                inMgr = false
            if (t === "[[mgr.prepend_keymap]]") { inBlock = true; continue }
            if (t.charAt(0) === "[" && t !== "[[mgr.prepend_keymap]]") inBlock = false
            if (t === "" && inBlock) continue

            const m = ("" + lines[i]).match(root.reInline)
            if (m && inMgr) {
                out.push({ on: root._display(m[1]), run: root._display(m[2]), desc: m[3] || "" })
                continue
            }

            if (inBlock) {
                const mo = t.match(/^on\s*=\s*(.+)$/i)
                const mr = t.match(/^run\s*=\s*(.+)$/i)
                const md = t.match(/^desc\s*=\s*(.+)$/i)
                if (mo) {
                    out.push({ on: root._display(mo[1]), run: "", desc: "" })
                    continue
                }
                if (mr && out.length > 0)
                    out[out.length - 1].run = root._display(mr[1])
                else if (md && out.length > 0)
                    out[out.length - 1].desc = root._unquote(md[1])
            }
        }
        return out
    }

    function combine() {
        const out = []
        const mine = {}
        for (let i = 0; i < root.userEntries.length; i++)
            mine["" + root.userEntries[i].on] = true
        for (let i = 0; i < root.defaultEntries.length; i++) {
            const d = root.defaultEntries[i]
            if (mine["" + d.on]) {
                let u = null
                for (let k = 0; k < root.userEntries.length; k++)
                    if (root.userEntries[k].on === d.on) { u = root.userEntries[k]; break }
                out.push({ on: d.on, run: u ? u.run : d.run, desc: u && u.desc !== "" ? u.desc : d.desc })
            } else {
                out.push({ on: d.on, run: d.run, desc: d.desc })
            }
        }
        for (let i = 0; i < root.userEntries.length; i++) {
            const u = root.userEntries[i]
            let found = false
            for (let j = 0; j < out.length; j++)
                if (out[j].on === u.on) { found = true; break }
            if (!found)
                out.push({ on: u.on, run: u.run, desc: u.desc })
        }
        root.entries = out
        root.loaded = true
        root.status = out.length + " bindings (default + yours)"
    }

    property var defaultEntries: []
    property var userEntries: []

    function setOn(index, value) {
        if (!root.entries[index]) return
        root.entries[index].on = value
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function setRun(index, value) {
        if (!root.entries[index]) return
        root.entries[index].run = value
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function setDesc(index, value) {
        if (!root.entries[index]) return
        root.entries[index].desc = value
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function remove(index) {
        root.entries.splice(index, 1)
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function add(on, run, desc) {
        if (("" + on).trim() === "" || ("" + run).trim() === "")
            return
        root.entries.push({ on: on, run: run, desc: desc || "" })
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function save() {
        if (!root.loaded) {
            root.status = "still loading — try Save again"
            return
        }
        const lines = ["[mgr]", "keymap = ["]
        for (let i = 0; i < root.entries.length; i++) {
            const e = root.entries[i]
            let line = "\t{ on = " + root._onToml(e.on) + ", run = " + root._quote(e.run)
            if (e.desc !== "")
                line += ", desc = " + root._quote(e.desc)
            line += " },"
            lines.push(line)
        }
        lines.push("]")
        writer.payload = lines.join("\n") + "\n"
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = ("" + this.text).replace(/\s*$/, "")
                const lines = text === "" ? [] : text.split("\n")
                root.userEntries = root.parseEntries(lines, false)
                if (root.defaultEntries.length > 0)
                    root.combine()
            }
        }
    }

    Process {
        id: defaultsReader
        command: ["cat", root.defaultsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = ("" + this.text).replace(/\s*$/, "")
                const lines = text === "" ? [] : text.split("\n")
                root.defaultEntries = root.parseEntries(lines, true)
                if (root.defaultEntries.length === 0) {
                    root.combine()
                    root.status = "defaults not found: " + root.defaultsPath
                    return
                }
                root.combine()
            }
        }
    }

    Process {
        id: writer
        property string payload: ""
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, root.path]
        onExited: (code, status) => {
            if (code !== 0) {
                root.status = "write failed (" + code + ")"
                return
            }
            root.dirty = false
            root.status = "saved " + root.entries.length + " bindings"
        }
    }

    Component.onCompleted: reload()
}