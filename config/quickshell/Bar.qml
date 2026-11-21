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

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
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
                        color: modelData.focused ? Theme.bg : Theme.fg
                    }
                    MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
                }
            }

            Text {                            // монитор ресурсов
                text: "CPU " + ("" + Math.round(SysInfo.cpu)).padStart(3, " ") + "%   RAM " + ("" + Math.round(SysInfo.memPct)).padStart(3, " ") + "%"
                color: Theme.fg; font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: UiState.toggle("monitor") }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.locale("ru_RU").toString(clock.date, "dddd d MMMM  HH:mm").replace(/(^|\s)(\S)/g, (m, a, b) => a + b.toUpperCase())
                color: Theme.fg; font.pixelSize: 14
            }

            Item { Layout.fillWidth: true }

            IconButton {                      // обход блокировок (щит)
                text: "\uf132"
                onClicked: UiState.toggle("services")
            }
            IconButton {                      // горячие клавиши (клавиатура)
                text: "\uf11c"
                onClicked: UiState.toggle("shortcuts")
            }
            IconButton {                      // выбор обоев (картинка)
                text: "\uf03e"
                onClicked: UiState.toggle("wallpaper")
            }
            IconButton {                      // смена темы (кисть)
                text: "\uf1fc"
                onClicked: UiState.toggle("themes")
            }
            Rectangle {                       // раскладка клавиатуры
                implicitWidth: layoutText.implicitWidth
                implicitHeight: 22
                radius: 6
                color: "transparent"
                Text {
                    id: layoutText
                    anchors.centerIn: parent
                    text: KbLayout.code
                    color: Theme.fg
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
                }
            }
            BatteryWidget {
                Layout.alignment: Qt.AlignVCenter

                panelBackground: Theme.bg
                panelForeground: Theme.fg
                panelSurface: Theme.surface
                panelAccent: Theme.accent
            }
            IconButton {                      // питание
                text: "\uf011"
                hoverColor: "#f38ba8"
                onClicked: UiState.toggle("power")
            }
        }
    }
}
