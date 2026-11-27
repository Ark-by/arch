pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды yazi. Поддерживаются два формата:
//  1) [mgr] keymap = [ { on = ..., run = ..., desc = ... }, ... ]  (штатный пресет)
//  2) управляемый блок # >>> ark-settings:keymap >>> с [[mgr.prepend_keymap]]
// Если файла нет — показываем штатный пресет из ~/.config/quickshell/defaults.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/yazi/keymap.toml"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/quickshell/defaults/yazi-keymap.toml"
    readonly property string beginMark: "# >>> ark-settings:keymap >>>"
    readonly property string endMark: "# <<< ark-settings:keymap <<<"

    property var lines: []
    property var entries: []
    property string mode: "none"
    property string status: ""
    property bool showingDefaults: false
    property bool dirty: false

    readonly property var reInline: /^\s*\{\s*on\s*=\s*(.+?),\s*run\s*=\s*(.+?)(?:,\s*desc\s*=\s*"([^"]*)")?\s*\}\s*,?\s*$/

    function reload() {
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

    function _displayOn(raw) {
        const s = ("" + raw).trim()
        if (s.charAt(0) === "[")
            return root._keys(s).join(" ")
        return root._unquote(s)
    }

    function _displayRun(raw) {
        const s = ("" + raw).trim()
        if (s.charAt(0) === "[")
            return root._keys(s).join(" ")
        return root._unquote(s)
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

    function parse() {
        root.entries = []
        root.mode = "none"

        const b = root.lines.indexOf(root.beginMark)
        const e = root.lines.indexOf(root.endMark)
        if (b >= 0 && e > b) {
            root.mode = "block"
            let cur = null
            for (let i = b + 1; i < e; i++) {
                const t = ("" + root.lines[i]).trim()
                if (t === "[[mgr.prepend_keymap]]") {
                    if (cur)
                        root.entries.push(cur)
                    cur = { entry: root.entries.length, onLine: -1, runLine: -1, descLine: -1, on: "", run: "", desc: "" }
                    continue
                }
                if (!cur)
                    continue
                if (t.indexOf("on =") === 0) {
                    cur.onLine = i
                    cur.on = root._displayOn(t.substring(4))
                } else if (t.indexOf("run =") === 0) {
                    cur.runLine = i
                    cur.run = root._displayRun(t.substring(5))
                } else if (t.indexOf("desc =") === 0) {
                    cur.descLine = i
                    cur.desc = root._unquote(t.substring(6))
                }
            }
            if (cur)
                root.entries.push(cur)
            return
        }

        let inMgr = false
        for (let i = 0; i < root.lines.length; i++) {
            const t = ("" + root.lines[i]).trim()
            if (t === "[mgr]") {
                inMgr = true
                continue
            }
            if (t.charAt(0) === "[" && t !== "[mgr]")
                inMgr = false
            if (!inMgr)
                continue
            const m = ("" + root.lines[i]).match(root.reInline)
            if (!m)
                continue
            root.entries.push({
                entry: root.entries.length,
                lineIndex: i,
                on: root._displayOn(m[1]),
                run: root._displayRun(m[2]),
                desc: m[3] || ""
            })
        }
        if (root.entries.length > 0)
            root.mode = "inline"
        else if (root.lines.length > 0)
            root.mode = "inline"
    }

    function _rebuildInline(index) {
        const e = root.entries[index]
        if (!e || e.lineIndex === undefined)
            return
        const indent = ("" + root.lines[e.lineIndex]).match(/^\s*/)[0]
        let line = indent + "{ on = " + root._onToml(e.on) + ", run = " + root._quote(e.run)
        if (e.desc !== "")
            line += ", desc = " + root._quote(e.desc)
        line += " },"
        root.lines[e.lineIndex] = line
        root.dirty = true
    }

    function setOn(index, value) {
        const e = root.entries[index]
        if (!e)
            return
        e.on = value
        if (root.mode === "inline") {
            root._rebuildInline(index)
        } else if (e.onLine >= 0) {
            root.lines[e.onLine] = "on = " + root._onToml(value)
            root.dirty = true
        }
        root.entries = root.entries.slice()
    }

    function setRun(index, value) {
        const e = root.entries[index]
        if (!e)
            return
        e.run = value
        if (root.mode === "inline") {
            root._rebuildInline(index)
        } else if (e.runLine >= 0) {
            root.lines[e.runLine] = "run = " + root._quote(value)
            root.dirty = true
        }
        root.entries = root.entries.slice()
    }

    function setDesc(index, value) {
        const e = root.entries[index]
        if (!e)
            return
        e.desc = value
        if (root.mode === "inline") {
            root._rebuildInline(index)
        } else if (e.descLine >= 0) {
            root.lines[e.descLine] = "desc = " + root._quote(value)
            root.dirty = true
        }
        root.entries = root.entries.slice()
    }

    function remove(index) {
        const e = root.entries[index]
        if (!e)
            return
        if (root.mode === "inline") {
            root.lines.splice(e.lineIndex, 1)
        } else {
            const from = Math.min(e.onLine, e.runLine, e.descLine >= 0 ? e.descLine : e.onLine)
            const to = Math.max(e.onLine, e.runLine, e.descLine)
            root.lines.splice(from - 1 >= 0 ? from - 1 : from, to - from + 2)
        }
        root.lines = root.lines.slice()
        root.parse()
        root.dirty = true
    }

    function add(on, run, desc) {
        if (("" + on).trim() === "" || ("" + run).trim() === "")
            return
        let line = "{ on = " + root._onToml(on) + ", run = " + root._quote(run)
        if (desc && desc !== "")
            line += ", desc = " + root._quote(desc)
        line += " },"

        if (root.mode === "inline") {
            let last = -1
            for (let i = 0; i < root.entries.length; i++)
                last = Math.max(last, root.entries[i].lineIndex)
            if (last >= 0)
                root.lines.splice(last + 1, 0, line)
            else
                root.lines.push(line)
        } else if (root.mode === "block") {
            const e = root.lines.indexOf(root.endMark)
            const block = ["[[mgr.prepend_keymap]]", "on = " + root._onToml(on), "run = " + root._quote(run)]
            if (desc && desc !== "")
                block.push("desc = " + root._quote(desc))
            block.push("")
            root.lines.splice(e, 0, ...block)
        } else {
            root.lines = ["[mgr]", "keymap = [", line, "]"]
        }
        root.lines = root.lines.slice()
        root.parse()
        root.dirty = true
    }

    function save() {
        writer.payload = root.lines.join("\n") + "\n"
        writer.running = true
    }

    function _parseText(raw) {
        const text = ("" + raw).replace(/\s*$/, "")
        root.lines = text === "" ? [] : text.split("\n")
        root.parse()
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = "" + this.text
                if (raw.trim() === "") {
                    defaultsReader.running = true
                    return
                }
                root.showingDefaults = false
                root._parseText(raw)
                root.dirty = false
                root.status = "loaded " + root.entries.length + " bindings"
            }
        }
    }

    Process {
        id: defaultsReader
        command: ["cat", root.defaultsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = "" + this.text
                if (raw.trim() === "") {
                    root.showingDefaults = true
                    root.dirty = false
                    root.status = "defaults not found: " + root.defaultsPath
                    return
                }
                root._parseText(raw)
                root.showingDefaults = true
                root.dirty = false
                root.status = "showing yazi defaults — Save writes keymap.toml"
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
            root.reload()
        }
    }

    Component.onCompleted: reload()
}