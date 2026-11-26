pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Запись шрифтов в kitty.conf и zed/settings.json.
// Правит только шрифтовые ключи, остальное содержимое файлов не трогает.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string kittyPath: home + "/.config/kitty/kitty.conf"
    readonly property string zedPath: home + "/.config/zed/settings.json"

    property string kittyText: ""
    property string zedText: ""
    property string status: ""

    signal done(string message)

    function _patchLine(text, key, value) {
        const re = new RegExp("^\\s*" + key + "\\s+.*$", "m")
        const line = key + " " + value
        if (re.test(text))
            return text.replace(re, line)
        const base = ("" + text).replace(/\s*$/, "")
        return (base === "" ? "" : base + "\n") + line + "\n"
    }

    function applyKitty(family, size) {
        const patched = root._patchLine(root._patchLine(root.kittyText, "font_family", family), "font_size", "" + size)
        root.kittyText = patched
        writer.target = root.kittyPath
        writer.payload = patched
        writer.after = "kitty"
        writer.running = true
    }

    function applyZed(bufFamily, bufSize, uiFamily, uiSize, termFamily, termSize) {
        let data
        try {
            data = JSON.parse(root.zedText)
        } catch (e) {
            root.status = "zed/settings.json: не JSON, ничего не меняю"
            return
        }
        data.buffer_font_family = bufFamily
        data.buffer_font_size = bufSize
        data.ui_font_family = uiFamily
        data.ui_font_size = uiSize
        const terminal = data.terminal && typeof data.terminal === "object" ? data.terminal : {}
        terminal.font_family = termFamily
        terminal.font_size = termSize
        data.terminal = terminal

        const patched = JSON.stringify(data, null, 2) + "\n"
        root.zedText = patched
        writer.target = root.zedPath
        writer.payload = patched
        writer.after = "zed"
        writer.running = true
    }

    function reload() {
        kittyReader.running = true
        zedReader.running = true
    }

    Component.onCompleted: reload()

    Process {
        id: kittyReader
        command: ["cat", root.kittyPath]
        stdout: StdioCollector {
            onStreamFinished: root.kittyText = this.text
        }
    }

    Process {
        id: zedReader
        command: ["cat", root.zedPath]
        stdout: StdioCollector {
            onStreamFinished: root.zedText = this.text
        }
    }

    Process {
        id: writer
        property string target: ""
        property string payload: ""
        property string after: ""
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "ark", writer.payload, writer.target]
        onExited: (code, status) => {
            if (code !== 0) {
                root.status = "write failed (" + code + ")"
                return
            }
            if (writer.after === "kitty") {
                kittyReload.running = true
                root.status = "kitty fonts saved"
                root.done("kitty fonts saved")
            } else if (writer.after === "zed") {
                root.status = "Zed fonts saved — restart Zed"
                root.done("Zed fonts saved — restart Zed")
                Quickshell.execDetached(["notify-send", "-a", "Settings", "Zed fonts",
                    "Restart Zed to apply the new fonts"])
            }
            root.reload()
        }
    }

    Process {
        id: kittyReload
        command: ["pkill", "-USR1", "-x", "kitty"]
    }
}