pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Бинды Zed: ~/.config/zed/keymap.json (массив секций с bindings).
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/zed/keymap.json"

    readonly property var actions: [
        "editor::Save", "editor::SaveAs", "editor::Copy", "editor::Cut", "editor::Paste",
        "editor::Undo", "editor::Redo", "editor::SelectAll", "editor::DeleteLine",
        "editor::DeleteToEndOfLine", "editor::DuplicateLineDown", "editor::DuplicateLineUp",
        "editor::MoveLineUp", "editor::MoveLineDown", "editor::ToggleComments",
        "editor::GoToLine", "editor::ShowCompletions", "editor::Hover",
        "editor::ToggleSoftWrap", "editor::Format",
        "workspace::NewFile", "workspace::CloseActiveItem", "workspace::ToggleLeftDock",
        "workspace::ToggleRightDock", "workspace::ToggleBottomDock", "workspace::ToggleZoom",
        "workspace::ActivatePaneLeft", "workspace::ActivatePaneRight",
        "file_finder::Toggle", "project_search::ToggleFocus", "command_palette::Toggle",
        "git_panel::ToggleFocus", "terminal_panel::ToggleFocus", "outline::Toggle"
    ]

    property var data: []
    property var entries: []
    property string status: ""
    property bool dirty: false

    function reload() {
        reader.running = true
    }

    function flatten() {
        const out = []
        for (let s = 0; s < root.data.length; s++) {
            const sec = root.data[s]
            if (!sec || !sec.bindings || typeof sec.bindings !== "object")
                continue
            for (const k in sec.bindings)
                out.push({
                    section: s,
                    context: sec.context || "",
                    key: k,
                    action: "" + sec.bindings[k]
                })
        }
        root.entries = out
    }

    function setKey(section, oldKey, newKey) {
        const sec = root.data[section]
        if (!sec || !sec.bindings || newKey === "" || oldKey === newKey)
            return
        const val = sec.bindings[oldKey]
        delete sec.bindings[oldKey]
        sec.bindings[newKey] = val
        root.flatten()
        root.dirty = true
    }

    function setAction(section, key, action) {
        const sec = root.data[section]
        if (!sec || !sec.bindings)
            return
        sec.bindings[key] = action
        root.flatten()
        root.dirty = true
    }

    function remove(section, key) {
        const sec = root.data[section]
        if (!sec || !sec.bindings)
            return
        delete sec.bindings[key]
        root.flatten()
        root.dirty = true
    }

    function add(context, key, action) {
        if (key === "" || action === "")
            return
        let target = -1
        for (let s = 0; s < root.data.length; s++) {
            const sec = root.data[s]
            if (sec && (sec.context || "") === context) {
                target = s
                break
            }
        }
        if (target < 0) {
            root.data.push({ context: context, bindings: ({}) })
            target = root.data.length - 1
        }
        if (!root.data[target].bindings)
            root.data[target].bindings = ({})
        root.data[target].bindings[key] = action
        root.flatten()
        root.dirty = true
    }

    function contexts() {
        const out = []
        for (let s = 0; s < root.data.length; s++) {
            const c = root.data[s] ? (root.data[s].context || "Global") : ""
            if (out.indexOf(c) < 0)
                out.push(c)
        }
        if (out.indexOf("Global") < 0)
            out.push("Global")
        return out
    }

    function save() {
        writer.payload = JSON.stringify(root.data, null, 2) + "\n"
        writer.running = true
    }

    Process {
        id: reader
        command: ["cat", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text)
                    root.data = Array.isArray(parsed) ? parsed : []
                    root.flatten()
                    root.dirty = false
                    root.status = "loaded " + root.entries.length + " bindings"
                } catch (e) {
                    root.status = "keymap.json: " + e
                }
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
            root.status = "saved"
            root.reload()
            Quickshell.execDetached(["notify-send", "-a", "Settings", "Zed keymap",
                "Restart Zed to apply keybindings"])
        }
    }

    Component.onCompleted: reload()
}