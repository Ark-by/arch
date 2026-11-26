import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: pane

    property string newOn: ""
    property string newRun: ""
    property string newDesc: ""

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
            spacing: 2

            Text {
                width: parent.width
                text: "yazi keymap: managed block in ~/.config/yazi/keymap.toml. Lines outside the block are left untouched."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Text {
                width: parent.width
                text: YaziKeys.status
                color: Theme.muted
                font.pixelSize: 11
                bottomPadding: 4
            }

            Repeater {
                model: YaziKeys.entries

                Rectangle {
                    required property var modelData
                    required property int index

                    width: col.width
                    height: 84
                    radius: 8
                    color: Qt.alpha(Theme.surface, 0.4)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        text: "on"
                        color: Theme.muted
                        font.pixelSize: 10
                    }

                    Rectangle {
                        id: yOn
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: yRemove.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        height: 24
                        radius: 6
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.color: yOnInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: yOnInput
                            anchors.fill: parent
                            anchors.margins: 5
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: modelData.on
                            selectByMouse: true
                            clip: true
                            onEditingFinished: YaziKeys.setOn(index, text)
                        }
                    }

                    Rectangle {
                        id: yRun
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: yRemove.left
                        anchors.rightMargin: 8
                        anchors.top: yOn.bottom
                        anchors.topMargin: 4
                        height: 24
                        radius: 6
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.color: yRunInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: yRunInput
                            anchors.fill: parent
                            anchors.margins: 5
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: modelData.run
                            selectByMouse: true
                            clip: true
                            onEditingFinished: YaziKeys.setRun(index, text)
                        }
                    }

                    Rectangle {
                        id: yRemove
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        width: 26
                        height: 26
                        radius: 6
                        color: yRemoveMouse.containsMouse ? Qt.alpha(Theme.error, 0.25) : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: Theme.error
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: yRemoveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: YaziKeys.remove(index)
                        }
                    }
                }
            }

            Item { width: 1; height: 12 }

            Text {
                text: "Add a binding"
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 4
            }

            Text {
                text: "Keys (space separated, e.g. g s)"
                color: Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                width: col.width
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: yNewOn.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: yNewOn
                    anchors.fill: parent
                    anchors.margins: 7
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: pane.newOn
                    selectByMouse: true
                    clip: true
                    onTextEdited: pane.newOn = text
                }
            }

            Text {
                text: "Run (yazi command, e.g. shell 'echo hi' --)"
                color: Theme.fg
                font.pixelSize: 12
                topPadding: 4
            }

            Rectangle {
                width: col.width
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: yNewRun.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: yNewRun
                    anchors.fill: parent
                    anchors.margins: 7
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: pane.newRun
                    selectByMouse: true
                    clip: true
                    onTextEdited: pane.newRun = text
                }
            }

            Row {
                width: col.width
                spacing: 8
                topPadding: 10

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: yAdd.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Add"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: yAdd
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            YaziKeys.add(pane.newOn, pane.newRun, pane.newDesc)
                            pane.newOn = ""
                            pane.newRun = ""
                        }
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: ySave.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: ySave
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: YaziKeys.save()
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: yRevert.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Revert"
                        color: Theme.fg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: yRevert
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: YaziKeys.reload()
                    }
                }
            }
        }
    }
}