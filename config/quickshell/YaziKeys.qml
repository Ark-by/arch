pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды yazi: в списке показываются штатные (defaults) и пользовательские.
// Редактируются только пользовательские; Save пишет ~/.config/yazi/keymap.toml.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/yazi/keymap.toml"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/quickshell/defaults/yazi-keymap.toml"
    readonly property string beginMark: "# >>> ark-settings:keymap >>>"
    readonly property string endMark: "# <<< ark-settings:keymap <<<"

    property var userLines: []
    property var userEntries: []
    property var defaultEntries: []
    property var entries: []
    property string mode: "none"
    property string status: ""
    property bool loaded: false
    property bool defaultsLoaded: false
    property bool dirty: false

    readonly property var reInline: /^\s*\{\s*on\s*=\s*(.+?),\s*run\s*=\s*(.+?)(?:,\s*desc\s*=\s*"([^"]*)")?\s*\}\s*,?\s*$/

    function reload() {
        root.loaded = false
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

    function _hasHeaders(lines) {
        for (let i = 0; i < lines.length; i++)
            if (("" + lines[i]).trim() === "[[mgr.prepend_keymap]]")
                return true
        return false
    }

    // Разбор пользовательского файла
    function parseUser() {
        root.userEntries = []
        root.mode = "none"
        const lines = root.userLines
        const b = lines.indexOf(root.beginMark)
        const e = lines.indexOf(root.endMark)
        const hasMarkers = b >= 0 && e > b

        if (hasMarkers || root._hasHeaders(lines)) {
            root.mode = "block"
            const from = hasMarkers ? b + 1 : 0
            const to = hasMarkers ? e : lines.length
            let cur = null
            for (let i = from; i < to; i++) {
                const t = ("" + lines[i]).trim()
                if (t === "[[mgr.prepend_keymap]]") {
                    if (cur)
                        root.userEntries.push(cur)
                    cur = {
                        index: root.userEntries.length,
                        onLine: -1, runLine: -1, descLine: -1,
                        on: "", run: "", desc: ""
                    }
                    continue
                }
                if (!cur)
                    continue
                let m = t.match(/^on\s*=\s*(.+)$/i)
                if (m) { cur.onLine = i; cur.on = root._display(m[1]); continue }
                m = t.match(/^run\s*=\s*(.+)$/i)
                if (m) { cur.runLine = i; cur.run = root._display(m[1]); continue }
                m = t.match(/^desc\s*=\s*(.+)$/i)
                if (m) { cur.descLine = i; cur.desc = root._unquote(m[1]) }
            }
            if (cur)
                root.userEntries.push(cur)
            return
        }

        let inMgr = false
        for (let i = 0; i < lines.length; i++) {
            const t = ("" + lines[i]).trim()
            if (t === "[mgr]") { inMgr = true; continue }
            if (t.charAt(0) === "[" && t !== "[mgr]")
                inMgr = false
            if (!inMgr)
                continue
            const m = ("" + lines[i]).match(root.reInline)
            if (!m)
                continue
            root.userEntries.push({
                index: root.userEntries.length,
                lineIndex: i,
                on: root._display(m[1]),
                run: root._display(m[2]),
                desc: m[3] || ""
            })
        }
        if (root.userEntries.length > 0)
            root.mode = "inline"
        else if (lines.length > 0)
            root.mode = "inline"
    }

    function parseDefaults(raw) {
        root.defaultEntries = []
        const text = ("" + raw).replace(/\s*$/, "")
        if (text === "")
            return
        const lines = text.split("\n")
        let inMgr = false
        for (let i = 0; i < lines.length; i++) {
            const t = ("" + lines[i]).trim()
            if (t === "[mgr]") { inMgr = true; continue }
            if (t.charAt(0) === "[" && t !== "[mgr]")
                inMgr = false
            if (!inMgr)
                continue
            const m = ("" + lines[i]).match(root.reInline)
            if (!m)
                continue
            root.defaultEntries.push({
                on: root._display(m[1]),
                run: root._display(m[2]),
                desc: m[3] || ""
            })
        }
    }

    function combine() {
        const out = []
        // сначала свои бинды, чтобы были наверху
        for (let i = 0; i < root.userEntries.length; i++) {
            const u = root.userEntries[i]
            out.push({
                source: "user",
                index: u.index,
                on: u.on, run: u.run, desc: u.desc,
                lineIndex: u.lineIndex, onLine: u.onLine, runLine: u.runLine, descLine: u.descLine
            })
        }
        for (let i = 0; i < root.defaultEntries.length; i++) {
            const d = root.defaultEntries[i]
            out.push({ source: "default", on: d.on, run: d.run, desc: d.desc })
        }
        root.entries = out
        root.status = "yours " + root.userEntries.length + " · built-in " + root.defaultEntries.length
    }

    function _rebuildInline(index) {
        const e = root.userEntries[index]
        if (!e || e.lineIndex === undefined)
            return
        const indent = ("" + root.userLines[e.lineIndex]).match(/^\s*/)[0]
        let line = indent + "{ on = " + root._onToml(e.on) + ", run = " + root._quote(e.run)
        if (e.desc !== "")
            line += ", desc = " + root._quote(e.desc)
        line += " },"
        root.userLines[e.lineIndex] = line
        root.dirty = true
    }

    function setOn(index, value) {
        const e = root.userEntries[index]
        if (!e)
            return
        e.on = value
        if (root.mode === "inline")
            root._rebuildInline(index)
        else if (e.onLine >= 0) {
            root.userLines[e.onLine] = "on = " + root._onToml(value)
            root.dirty = true
        }
        root.combine()
    }

    function setRun(index, value) {
        const e = root.userEntries[index]
        if (!e)
            return
        e.run = value
        if (root.mode === "inline")
            root._rebuildInline(index)
        else if (e.runLine >= 0) {
            root.userLines[e.runLine] = "run = " + root._quote(value)
            root.dirty = true
        }
        root.combine()
    }

    function setDesc(index, value) {
        const e = root.userEntries[index]
        if (!e)
            return
        e.desc = value
        if (root.mode === "inline")
            root._rebuildInline(index)
        else if (e.descLine >= 0) {
            root.userLines[e.descLine] = "desc = " + root._quote(value)
            root.dirty = true
        }
        root.combine()
    }

    function remove(index) {
        const e = root.userEntries[index]
        if (!e)
            return
        if (root.mode === "inline") {
            root.userLines.splice(e.lineIndex, 1)
        } else {
            const from = Math.min(e.onLine, e.runLine, e.descLine >= 0 ? e.descLine : e.onLine)
            const to = Math.max(e.onLine, e.runLine, e.descLine)
            const start = from > 0 ? from - 1 : from
            root.userLines.splice(start, to - start + 1)
        }
        root.userLines = root.userLines.slice()
        root.parseUser()
        root.combine()
        root.dirty = true
    }

    function add(on, run, desc) {
        if (("" + on).trim() === "" || ("" + run).trim() === "")
            return
        const lines = root.userLines.slice()
        if (root.mode === "block") {
            const idx = lines.indexOf(root.endMark)
            const block = ["[[mgr.prepend_keymap]]", "on = " + root._onToml(on), "run = " + root._quote(run)]
            if (desc && desc !== "")
                block.push("desc = " + root._quote(desc))
            block.push("")
            const at = idx < 0 ? lines.length : idx
            for (let i = block.length - 1; i >= 0; i--)
                lines.splice(at, 0, block[i])
        } else {
            let line = "{ on = " + root._onToml(on) + ", run = " + root._quote(run)
            if (desc && desc !== "")
                line += ", desc = " + root._quote(desc)
            line += " },"
            if (lines.length === 0) {
                lines.push("[mgr]")
                lines.push("keymap = [")
            }
            let last = -1
            for (let i = 0; i < root.userEntries.length; i++)
                if (root.userEntries[i].lineIndex !== undefined)
                    last = Math.max(last, root.userEntries[i].lineIndex)
            if (last >= 0)
                lines.splice(last + 1, 0, line)
            else
                lines.push(line)
        }
        root.userLines = lines
        root.parseUser()
        root.combine()
        root.dirty = true
    }

    function save() {
        if (!root.loaded) {
            root.status = "still loading — try Save again"
            return
        }
        writer.payload = root.userLines.join("\n") + "\n"
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = "" + this.text
                const text = raw.replace(/\s*$/, "")
                root.userLines = text === "" ? [] : text.split("\n")
                root.parseUser()
                root.loaded = true
                root.combine()
                if (root.defaultEntries.length === 0)
                    defaultsReader.running = true
            }
        }
    }

    Process {
        id: defaultsReader
        command: ["cat", root.defaultsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDefaults(this.text)
                root.defaultsLoaded = true
                root.combine()
                if (root.defaultEntries.length === 0)
                    root.status = "defaults not found: " + root.defaultsPath
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