import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Бар собирается из модулей, порядок и включение — в настройках (Super+S -> Bar).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        readonly property string pos: Settings.get("bar.position", "top")
        readonly property bool hiddenByFullscreen: Settings.get("bar.hideFullscreen", false)
            && Hyprland.activeToplevel !== null
            && Hyprland.activeToplevel.fullscreen === true

        anchors {
            top: pos === "top"
            bottom: pos === "bottom"
            left: true
            right: true
        }

        implicitHeight: hiddenByFullscreen ? 0 : Settings.get("bar.height", 36)
        visible: !hiddenByFullscreen
        color: Qt.alpha(Theme.bg, Settings.get("bar.opacity", 0.7))
        WlrLayershell.namespace: "qs-bar"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: hiddenByFullscreen ? ExclusionMode.Ignore : ExclusionMode.Auto

        // Включённые модули стороны, в сохранённом порядке
        function moduleIds(side) {
            const list = Settings.get("bar.modules." + side, [])
            const out = []
            for (let i = 0; i < list.length; i++) {
                const m = list[i]
                if (m && m.enabled && m.id)
                    out.push(m.id)
            }
            return out
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Repeater {
                model: bar.moduleIds("left")
                BarModule { kind: modelData }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Repeater {
                model: bar.moduleIds("center")
                BarModule { kind: modelData }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Repeater {
                model: bar.moduleIds("right")
                BarModule { kind: modelData }
            }
        }
    }
}