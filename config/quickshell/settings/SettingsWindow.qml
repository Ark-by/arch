import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import Quickshell.Io
import Quickshell.Wayland

// Окно настроек: 900x620 по центру, сайдбар + страницы.
// Открывается по Super+S (qs ipc call settings open) или кнопкой в баре.
PanelWindow {
    id: win

    visible: UiState.panel === "settings"
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // id — для IpcHandler, key — ключ в settings-файле
    readonly property var pages: [
        { id: "bar",        key: "bar",       name: "Bar",        icon: "\uf0c9", source: "pages/BarPage.qml" },
        { id: "themes",     key: "theme",     name: "Themes",     icon: "\uf1fc", source: "pages/ThemesPage.qml" },
        { id: "palette",    key: "theme",     name: "Palette",    icon: "\uf1fb", source: "pages/PalettePage.qml" },
        { id: "wallpapers", key: "wallpaper", name: "Wallpapers", icon: "\uf03e", source: "pages/WallpapersPage.qml" },
        { id: "fonts",      key: "fonts",     name: "Fonts",      icon: "\uf031", source: "pages/FontsPage.qml" },
        { id: "keys",       key: "keys",      name: "Keys",       icon: "\uf11c", source: "pages/KeysPage.qml" }
    ]

    property int currentPage: 0
    property bool confirmResetAll: false
    property string status: ""

    function openPage(id) {
        if (id) {
            for (let i = 0; i < pages.length; i++) {
                if (pages[i].id === id) {
                    currentPage = i
                    break
                }
            }
        }
        confirmResetAll = false
        status = ""
        UiState.panel = "settings"
    }

    function close() {
        UiState.panel = ""
        confirmResetAll = false
        status = ""
    }

    function applyNow() {
        Settings.apply()
    }

    function resetCurrentSection() {
        Settings.resetSection(pages[currentPage].key)
        status = "Section reset to defaults"
    }

    function resetEverything() {
        if (!confirmResetAll) {
            confirmResetAll = true
            status = "Press again to reset everything"
            confirmTimer.restart()
            return
        }
        confirmResetAll = false
        Settings.resetAll()
        status = "All overrides removed"
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: {
            win.confirmResetAll = false
            win.status = ""
        }
    }

    Timer {
        id: statusTimer
        interval: 2500
        onTriggered: win.status = ""
    }

    Connections {
        target: Settings
        function onSaved() {
            win.status = "Applied"
            statusTimer.restart()
        }
        function onSaveFailed(code) {
            win.status = "Save failed (" + code + ") — values kept, try again"
            statusTimer.restart()
        }
    }

    IpcHandler {
        target: "settings"
        function open(): void { win.openPage("") }
        function openPage(page: string): void { win.openPage(page) }
        function close(): void { win.close() }
        function apply(): void { win.applyNow() }
    }

    // Клик по пустому месту закрывает окно
    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    Rectangle {
        id: frame
        width: 900
        height: 620
        anchors.centerIn: parent
        radius: 16
        color: Qt.alpha(Theme.bg, 0.92)
        border.color: Theme.accent
        border.width: 1
        focus: true

        Keys.onEscapePressed: win.close()

        // Поглощает клики внутри окна, чтобы фон не закрывал его
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ---------- Заголовок ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Settings"
                    color: Theme.fg
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: win.status
                    color: win.status.indexOf("fail") >= 0 ? Theme.error : Theme.muted
                    font.pixelSize: 12
                    visible: win.status !== ""
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // ---------- Сайдбар + страница ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true
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
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Qt.alpha(Theme.bg, 0.6)
                    border.color: Theme.border
                    border.width: 1

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        source: win.pages[win.currentPage].source
                    }
                }
            }

            // ---------- Футер ----------
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: Settings.dirty ? "Unsaved changes" : "No changes"
                    color: Settings.dirty ? Theme.warning : Theme.muted
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 132
                    height: 34
                    radius: 8
                    color: resSectionMouse.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Reset section"
                        color: Theme.fg
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: resSectionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.resetCurrentSection()
                    }
                }

                Rectangle {
                    width: 150
                    height: 34
                    radius: 8
                    color: win.confirmResetAll ? Qt.alpha(Theme.error, 0.25) : (resAllMouse.containsMouse ? Theme.surface : "transparent")
                    border.color: win.confirmResetAll ? Theme.error : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: win.confirmResetAll ? "Confirm reset?" : "Reset all"
                        color: win.confirmResetAll ? Theme.error : Theme.fg
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: resAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.resetEverything()
                    }
                }

                Rectangle {
                    width: 110
                    height: 34
                    radius: 8
                    color: applyMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: Theme.bg
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.applyNow()
                    }
                }
            }
        }
    }
}