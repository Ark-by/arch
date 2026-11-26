pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды yazi через управляемый блок в ~/.config/yazi/keymap.toml.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/yazi/keymap.toml"
    readonly property string beginMark: "# >>> ark-settings:keymap >>>"
    readonly property string endMark: "# <<< ark-settings:keymap <<<"

    property var lines: []
    property var entries: []
    property string status: ""
    property bool dirty: false

    function reload() {
        reader.running = true
    }

    function parseOn(text) {
        const out = []
        const re = /"([^"]*)"/g
        let m
        while ((m = re.exec(text)) !== null)
            out.push(m[1])
        return out
    }

    function parseValue(text) {
        const m = ("" + text).match(/^[a-z_]+\s*=\s*(.*)$/i)
        if (!m)
            return ""
        let v = m[1].trim()
        if (v.length >= 2 && v.charAt(0) === '"' && v.charAt(v.length - 1) === '"')
            v = v.slice(1, -1).replace(/\\"/g, '"')
        else if (v.length >= 2 && v.charAt(0) === "'" && v.charAt(v.length - 1) === "'")
            v = v.slice(1, -1)
        return v
    }

    function parse() {
        const out = []
        const b = root.lines.indexOf(root.beginMark)
        const e = root.lines.indexOf(root.endMark)
        if (b < 0 || e <= b) {
            root.entries = []
            return
        }
        let cur = null
        for (let i = b + 1; i < e; i++) {
            const line = ("" + root.lines[i]).trim()
            if (line === "[[mgr.prepend_keymap]]") {
                if (cur)
                    out.push(cur)
                cur = { on: "", run: "", desc: "" }
                continue
            }
            if (!cur)
                continue
            if (line.indexOf("on =") === 0)
                cur.on = root.parseOn(line).join(" ")
            else if (line.indexOf("run =") === 0)
                cur.run = root.parseValue(line)
            else if (line.indexOf("desc =") === 0)
                cur.desc = root.parseValue(line)
        }
        if (cur)
            out.push(cur)
        root.entries = out
    }

    function setOn(index, on) {
        if (!root.entries[index])
            return
        root.entries[index].on = on
        root.dirty = true
    }

    function setRun(index, run) {
        if (!root.entries[index])
            return
        root.entries[index].run = run
        root.dirty = true
    }

    function setDesc(index, desc) {
        if (!root.entries[index])
            return
        root.entries[index].desc = desc
        root.dirty = true
    }

    function remove(index) {
        root.entries.splice(index, 1)
        root.dirty = true
        root.entries = root.entries.slice()
    }

    function add(on, run, desc) {
        if (("" + on).trim() === "" || ("" + run).trim() === "")
            return
        root.entries.push({ on: on, run: run, desc: desc })
        root.entries = root.entries.slice()
        root.dirty = true
    }

    function quote(text) {
        return '"' + ("" + text).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + '"'
    }

    function buildBlock() {
        const block = [root.beginMark]
        for (let i = 0; i < root.entries.length; i++) {
            const e = root.entries[i]
            block.push("[[mgr.prepend_keymap]]")
            const keys = ("" + e.on).trim().split(/\s+/).filter(k => k !== "")
            const on = keys.map(k => '"' + k + '"').join(", ")
            block.push("on = [ " + on + " ]")
            block.push("run = " + root.quote(e.run))
            if (e.desc !== "")
                block.push("desc = " + root.quote(e.desc))
            block.push("")
        }
        block.push(root.endMark)
        return block
    }

    function save() {
        const block = root.buildBlock()
        const b = root.lines.indexOf(root.beginMark)
        const e = root.lines.indexOf(root.endMark)
        let out
        if (b >= 0 && e > b) {
            out = root.lines.slice(0, b).concat(block, root.lines.slice(e + 1))
        } else {
            out = root.lines.slice()
            if (out.length > 0 && out[out.length - 1].trim() !== "")
                out.push("")
            out = out.concat(block)
        }
        writer.payload = out.join("\n") + "\n"
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = ("" + this.text).replace(/\s*$/, "")
                root.lines = text === "" ? [] : text.split("\n")
                root.parse()
                root.dirty = false
                if (root.lines.indexOf(root.beginMark) < 0)
                    root.status = "no managed block yet — Save creates it"
                else
                    root.status = "loaded " + root.entries.length + " bindings"
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
            root.status = "saved"
            root.reload()
        }
    }

    Component.onCompleted: reload()
}