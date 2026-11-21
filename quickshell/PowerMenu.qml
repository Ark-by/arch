import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: UiState.panel === "power"
    anchors { top: true; right: true }
    margins { top: 42; right: 8 }
    implicitWidth: 200
    implicitHeight: 200
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function run(cmd) {
        UiState.panel = ""
        Quickshell.execDetached(cmd)
    }

    Rectangle {
        anchors.fill: parent
        focus: visible
        radius: 12
        color: Qt.alpha(Theme.bg, 0.9)
        border.color: Theme.accent
        border.width: 1

        Keys.onEscapePressed: UiState.panel = ""

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: [
                    { label: "Выключить",    icon: "\uf011", cmd: ["systemctl", "poweroff"] },
                    { label: "Перезагрузка", icon: "\uf021", cmd: ["systemctl", "reboot"] },
                    { label: "Спящий режим", icon: "\uf186", cmd: ["systemctl", "suspend"] },
                    { label: "Выйти",        icon: "\uf08b", cmd: ["hyprctl", "dispatch", "exit"] }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 38
                    radius: 8
                    color: ma.containsMouse ? Theme.surface : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Theme.accent
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 38
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: Theme.fg
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(modelData.cmd)
                    }
                }
            }
        }
    }
}
