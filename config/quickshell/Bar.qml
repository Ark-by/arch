import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 36
        color: Qt.alpha(Theme.bg, 0.7)
        WlrLayershell.namespace: "qs-bar"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Auto

        SystemClock { id: clock; precision: SystemClock.Minutes }

        // ---------------- ЛЕВАЯ ГРУППА ----------------
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            IconButton {                      // меню приложений (логотип Arch)
                text: "\uf303"
                baseColor: Theme.accent
                hoverColor: Theme.fg
                onClicked: UiState.toggle("launcher")
            }

            Repeater {
                model: Hyprland.workspaces.values
                Rectangle {
                    required property var modelData
                    implicitWidth: 26; implicitHeight: 22; radius: 6
                    color: modelData.focused ? Theme.accent : Theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        color: modelData.focused ? Theme.bg : Theme.accent
                        font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
                }
            }

            Text {                            // монитор ресурсов
                text: "CPU " + ("" + Math.round(SysInfo.cpu)).padStart(3, "") + "% RAM " + ("" + Math.round(SysInfo.memPct)).padStart(3, "") + "%"
                color: Theme.accent; font.pixelSize: 13; font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: UiState.toggle("monitor") }
            }
        }

        // ---------------- ЦЕНТР: ДАТА И ВРЕМЯ ----------------
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale("ru_RU").toString(clock.date, "dddd d MMMM  HH:mm").replace(/(^|\s)(\S)/g, (m, a, b) => a + b.toUpperCase())
            color: Theme.accent
            font.pixelSize: 14
            font.bold: true
        }

        // ---------------- ПРАВАЯ ГРУППА ----------------
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            IconButton {                      // обход блокировок (щит)
                text: "\uf132"
                baseColor: Theme.accent
                hoverColor: Theme.fg
                onClicked: UiState.toggle("services")
            }
            IconButton {                      // горячие клавиши (клавиатура)
                text: "\uf11c"
                baseColor: Theme.accent
                hoverColor: Theme.fg
                onClicked: UiState.toggle("shortcuts")
            }
            IconButton {                      // выбор обоев (картинка)
                text: "\uf03e"
                baseColor: Theme.accent
                hoverColor: Theme.fg
                onClicked: UiState.toggle("wallpaper")
            }
            IconButton {                      // смена темы (кисть)
                text: "\uf1fc"
                baseColor: Theme.accent
                hoverColor: Theme.fg
                onClicked: UiState.toggle("themes")
            }
            IconButton {                      // раскладка клавиатуры
                            text: KbLayout.code
                            font.pixelSize: 15
                            font.bold: true
                            baseColor: Theme.accent
                            hoverColor: Theme.fg
                            onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
            }
            IconButton {                      // питание
                text: "\uf011"
                hoverColor: "#f38ba8"
                onClicked: UiState.toggle("power")
            }
        }
    }
}
