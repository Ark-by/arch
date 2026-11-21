import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    visible: UiState.panel === "themes"
    implicitWidth: 360
    implicitHeight: 480
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        focus: visible
        radius: 16
        color: Qt.alpha(Theme.bg, 0.8)
        border.color: Theme.accent
        border.width: 1

        Keys.onEscapePressed: UiState.panel = ""

        FolderListModel {
            id: themes
            folder: "file://" + UiState.home + "/.config/themes"
            nameFilters: ["*.json"]
            showDirs: false
        }

        ListView {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6
            clip: true
            model: themes

            delegate: Rectangle {
                id: row
                required property string fileBaseName
                required property string filePath

                property var pal: null     // цвета этой темы, читаются из её файла
                readonly property bool isCurrent: pal !== null
                    && Qt.colorEqual(Theme.bg, pal.bg) && Qt.colorEqual(Theme.accent, pal.accent)

                width: ListView.view.width
                height: 46
                radius: 10
                color: pal ? pal.bg : Theme.surface
                border.color: isCurrent && pal ? pal.accent : (pal ? pal.surface : Theme.muted)
                border.width: isCurrent ? 2 : 1

                FileView {
                    path: row.filePath
                    onLoaded: row.pal = JSON.parse(text())
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: (row.isCurrent ? "● " : "") + (row.pal && row.pal.name ? row.pal.name : row.fileBaseName)
                    color: row.pal ? row.pal.fg : Theme.fg
                    font.pixelSize: 15
                }

                // Образцы цветов темы: красный, зелёный, жёлтый, синий, розовый, бирюзовый
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: row.pal && row.pal.ansi ? [1, 2, 3, 4, 5, 6] : []
                        Rectangle {
                            required property int modelData
                            width: 12; height: 12; radius: 6
                            color: row.pal.ansi[modelData]
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Quickshell.execDetached([UiState.home + "/.local/bin/set-theme", row.fileBaseName])
                        UiState.panel = ""
                    }
                }
            }
        }
    }
}
