import QtQuick
import Quickshell
import Quickshell.Wayland

// Настройки: Темы и Обои. Открывается по Super+T / Super+W или шестерёнкой в баре.
PanelWindow {
    id: win

    visible: UiState.panel === "settings"
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property var pages: [
        { id: "themes", name: "Themes", icon: "\uf1fc", source: "ThemesPage.qml" },
        { id: "wallpapers", name: "Wallpapers", icon: "\uf03e", source: "WallpapersPage.qml" }
    ]

    property int currentPage: 0

    function showPage(index) {
        currentPage = index
        UiState.panel = "settings"
    }

    // Super+T / Super+W: открыть страницу, повторное нажатие — закрыть
    function togglePage(index) {
        if (UiState.panel === "settings" && currentPage === index) {
            UiState.panel = ""
            return
        }
        showPage(index)
    }

    onVisibleChanged: if (visible) Qt.callLater(() => panel.forceActiveFocus())

    function close() {
        UiState.panel = ""
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    Rectangle {
        id: panel
        width: 900
        height: 620
        anchors.centerIn: parent
        radius: 16
        color: Qt.alpha(Theme.bg, 0.92)
        border.color: Theme.accent
        border.width: 1
        focus: true

        Keys.onEscapePressed: win.close()

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Themes & Wallpapers"
                color: Theme.fg
                font.pixelSize: 20
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Row {
                width: parent.width
                height: parent.height - 70
                spacing: 12

                Rectangle {
                    width: 190
                    height: parent.height
                    radius: 12
                    color: Qt.alpha(Theme.surface, 0.6)

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Repeater {
                            model: win.pages

                            Rectangle {
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: 38
                                radius: 9
                                color: win.currentPage === index ? Qt.alpha(Theme.accent, 0.22) : "transparent"
                                border.color: win.currentPage === index ? Theme.accent : "transparent"
                                border.width: 1

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    color: win.currentPage === index ? Theme.accent : Theme.muted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: win.currentPage === index ? Theme.fg : Theme.muted
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.currentPage = index
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 202
                    height: parent.height
                    radius: 12
                    color: Qt.alpha(Theme.bg, 0.6)
                    border.color: Theme.border
                    border.width: 1

                    Loader {
                        anchors.fill: parent
                        source: win.pages[win.currentPage].source
                    }
                }
            }
        }
    }
}