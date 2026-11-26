import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

    property string newName: ""
    property string pendingDelete: ""
    property string status: ""

    function baseOf(t) {
        return ThemeStore._base(t)
    }

    function swatches(t) {
        const out = []
        if (!t) return out
        const keys = ["bg", "surface", "fg", "accent", "muted"]
        for (let i = 0; i < keys.length; i++)
            if (t[keys[i]]) out.push(t[keys[i]])
        if (t.ansi)
            for (let i = 1; i <= 6 && i < t.ansi.length; i++)
                out.push(t.ansi[i])
        return out
    }

    function duplicateActive() {
        const t = ThemeStore.find(ThemeStore.activeBase())
        if (!t) { page.status = "Active theme not found"; return }
        if (ThemeStore.duplicate(t, page.newName)) {
            page.status = "Duplicated as " + page.newName
            page.newName = ""
        } else {
            page.status = "Bad name or already exists"
        }
    }

    function applyTheme(t) {
        ThemeStore.apply(page.baseOf(t))
        page.status = "Applied " + page.baseOf(t)
    }

    function askDelete(t) {
        const b = page.baseOf(t)
        if (b === ThemeStore.activeBase()) {
            page.status = "Cannot delete the active theme — switch first"
            page.pendingDelete = ""
            return
        }
        if (page.pendingDelete === b) {
            ThemeStore.remove(t)
            page.pendingDelete = ""
            page.status = "Deleted " + b
        } else {
            page.pendingDelete = b
            page.status = "Press delete again to remove " + b
            confirmTimer.restart()
        }
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: page.pendingDelete = ""
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            x: 18
            y: 18
            width: parent.width - 36
            spacing: 6

            Text {
                text: "Themes"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Apply a palette to the whole system. The palette is generated into kitty, Zed, yazi, cmus, Hyprland and hyprlogin."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 8
                color: Qt.alpha(Theme.surface, 0.45)
                border.color: Theme.border
                border.width: 1

                TextInput {
                    id: dupInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 110
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 12
                    text: page.newName
                    selectByMouse: true
                    onTextChanged: page.newName = text
                    Text {
                        visible: dupInput.text === ""
                        text: "New name for a copy of the active theme"
                        color: Theme.muted
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100
                    height: 26
                    radius: 6
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Duplicate"
                        color: Theme.fg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.duplicateActive()
                    }
                }
            }

            Text {
                visible: page.status !== ""
                width: parent.width
                text: page.status
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                topPadding: 4
            }

            Repeater {
                model: ThemeStore.themes

                Rectangle {
                    required property var modelData

                    readonly property string base: page.baseOf(modelData)
                    readonly property bool active: base === ThemeStore.activeBase()

                    width: col.width
                    height: 78
                    radius: 10
                    color: Qt.alpha(Theme.surface, 0.45)
                    border.color: active ? Theme.accent : Theme.border
                    border.width: active ? 2 : 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        text: (parent.active ? "● " : "") + modelData.name
                        color: Theme.fg
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        spacing: 4

                        Repeater {
                            model: page.swatches(modelData)

                            Rectangle {
                                required property string modelData
                                width: 18
                                height: 14
                                radius: 3
                                color: modelData
                                border.color: Theme.bg
                                border.width: 1
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 6

                        Rectangle {
                            width: 74
                            height: 26
                            radius: 6
                            color: applyMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "Apply"
                                color: Theme.bg
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: applyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.applyTheme(modelData)
                            }
                        }

                        Rectangle {
                            width: 74
                            height: 26
                            radius: 6
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Palette"
                                color: Theme.fg
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ThemeStore.selected = page.baseOf(modelData)
                                    UiState.settingsPage = "palette"
                                }
                            }
                        }

                        Rectangle {
                            width: page.pendingDelete === page.baseOf(modelData) ? 96 : 74
                            height: 26
                            radius: 6
                            color: page.pendingDelete === page.baseOf(modelData) ? Qt.alpha(Theme.error, 0.25) : Theme.surface
                            border.color: page.pendingDelete === page.baseOf(modelData) ? Theme.error : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: page.pendingDelete === page.baseOf(modelData) ? "Confirm?" : "Delete"
                                color: page.pendingDelete === page.baseOf(modelData) ? Theme.error : Theme.fg
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.askDelete(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}