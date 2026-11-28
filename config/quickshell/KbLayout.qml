pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property string name: ""                         // например "Russian"
    readonly property string code: shortCode(root.name)

    // Полное название раскладки -> короткий код (в hyprland.lua только us,ru)
    function shortCode(n) {
        const l = n.toLowerCase()
        if (l === "") return "??"
        return l.includes("ru") ? "RU" : "EN"
    }

    // Hyprland присылает событие при каждой смене раскладки
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const i = event.data.lastIndexOf(",")
            root.name = i >= 0 ? event.data.slice(i + 1) : event.data
        }
    }

    // Начальное значение: спрашиваем у Hyprland, какая раскладка включена сейчас
    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards
                    const main = kbs.find(k => k.main) || kbs[0]
                    if (main && root.name === "") root.name = main.active_keymap
                } catch (e) {}
            }
        }
    }
}
