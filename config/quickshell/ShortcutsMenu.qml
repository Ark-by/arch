import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: UiState.panel === "shortcuts"
    implicitWidth: 760
    implicitHeight: Math.max(220, 64 + content.implicitHeight + 52)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var leftSections: []
    property var rightSections: []

    // Порядок разделов (остальные идут после них)
    readonly property var sectionOrder: ["Приложения", "Меню панели", "Окна", "Рабочие столы", "Система"]

    // То, что не является клавишей Hyprland (поэтому не читается автоматически)
    readonly property var extraItems: [
        { section: "Система", keys: "Alt + Shift", text: "Сменить раскладку" }
    ]

    onVisibleChanged: if (visible) { bindsProc.running = true; scope.forceActiveFocus() }

    // Превращает маску модификаторов и название клавиши в "Super + Q"
    function formatKeys(mask, key) {
        const parts = []
        if (mask & 64) parts.push("Super")
        if (mask & 4)  parts.push("Ctrl")
        if (mask & 8)  parts.push("Alt")
        if (mask & 1)  parts.push("Shift")
        const names = {
            "escape": "Esc", "return": "Enter", "space": "Space",
            "left": "←", "right": "→", "up": "↑", "down": "↓",
            "mouse:272": "ЛКМ", "mouse:273": "ПКМ", "mouse:274": "СКМ",
            "mouse_down": "Колесо ↓", "mouse_up": "Колесо ↑"
        }
        const k = String(key)
        const low = k.toLowerCase()
        if (low in names) parts.push(names[low])
        else parts.push(k.length === 1 ? k.toUpperCase() : k)
        return parts.join(" + ")
    }

    // Разбирает ответ hyprctl и раскладывает клавиши по двум колонкам
    function parseBinds(json) {
        let binds = []
        try { binds = JSON.parse(json) } catch (e) { return }

        const map = {}
        const seen = {}
        function add(section, keys, text) {
            const id = section + "|" + keys + "|" + text
            if (seen[id]) return
            seen[id] = true
            if (!map[section]) map[section] = []
            map[section].push({ keys: keys, text: text })
        }

        for (const b of binds) {
            let desc = b.description || ""
            if (desc === "") continue

            let keys = ""
            const bar = desc.indexOf(" | ")
            if (bar >= 0) { keys = desc.slice(bar + 3); desc = desc.slice(0, bar) }

            let section = "Прочее"
            const colon = desc.indexOf(": ")
            if (colon > 0) { section = desc.slice(0, colon); desc = desc.slice(colon + 2) }

            if (keys === "") keys = formatKeys(b.modmask, b.key)
            add(section, keys, desc)
        }
        for (const x of root.extraItems) add(x.section, x.keys, x.text)

        const names = Object.keys(map)
        names.sort((a, b) => {
            let ia = root.sectionOrder.indexOf(a)
            let ib = root.sectionOrder.indexOf(b)
            if (ia < 0) ia = 99
            if (ib < 0) ib = 99
            return ia - ib
        })

        // Каждый раздел кладём в ту колонку, где сейчас меньше строк
        const left = [], right = []
        let lc = 0, rc = 0
        for (const n of names) {
            const sec = { title: n, items: map[n] }
            const h = map[n].length + 2
            if (lc <= rc) { left.push(sec); lc += h } else { right.push(sec); rc += h }
        }
        root.leftSections = left
        root.rightSections = right
    }

    Process {
        id: bindsProc
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector { onStreamFinished: root.parseBinds(text) }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.alpha(Theme.bg, 0.9)
        border.color: Theme.accent
        border.width: 1

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: UiState.panel = ""

            Text {
                x: 24; y: 18
                text: "Горячие клавиши"
                color: Theme.fg
                font.pixelSize: 20
                font.bold: true
            }

            IconButton {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                text: "\uf00d"
                hoverColor: Theme.error
                onClicked: UiState.panel = ""
            }

            Text {
                visible: root.leftSections.length === 0 && root.rightSections.length === 0
                x: 24; y: 70
                width: parent.width - 48
                wrapMode: Text.WordWrap
                text: "Список пуст. Добавьте описания к клавишам в ~/.config/hypr/keybinds.lua"
                color: Theme.muted
                font.pixelSize: 14
            }

            Row {
                id: content
                x: 24; y: 64
                spacing: 32
                ShortcutColumn { width: 340; sections: root.leftSections }
                ShortcutColumn { width: 340; sections: root.rightSections }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                text: "Esc — закрыть"
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
}
