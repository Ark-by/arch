import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    visible: UiState.panel === "launcher"
    implicitWidth: 520
    implicitHeight: 420
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) {
        Qt.callLater(() => { search.text = ""; search.forceActiveFocus() })
    }

    ScriptModel {
        id: apps
        values: DesktopEntries.applications.values
            .filter(a => a.name.toLowerCase().includes(search.text.toLowerCase()))
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    function launch() {
        const e = apps.values[list.currentIndex]
        if (e) { e.execute(); UiState.panel = "" }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.alpha(Theme.bg, 0.8)
        border.color: Theme.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40; radius: 8; color: Theme.surface
                TextInput {
                    id: search
                    anchors.fill: parent; anchors.margins: 10
                    color: Theme.fg; font.pixelSize: 16
                    verticalAlignment: TextInput.AlignVCenter
                    onTextChanged: list.currentIndex = 0
                    Keys.onEscapePressed: UiState.panel = ""
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: win.launch()
                    Text {
                        visible: !search.text
                        text: "Поиск приложений…"
                        color: Theme.muted; font: search.font
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: apps
                highlightMoveDuration: 0
                delegate: Rectangle {
                    required property var modelData
                    width: list.width; height: 36; radius: 8
                    color: ListView.isCurrentItem ? Theme.surface : "transparent"
                    Image {
                        x: 8; anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22
                        source: Quickshell.iconPath(modelData.icon, true)
                    }
                    Text {
                        x: 42; anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name; color: Theme.fg; font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { modelData.execute(); UiState.panel = "" }
                    }
                }
            }
        }
    }
}