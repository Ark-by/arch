import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: pane

    property int pickingRow: -1
    property bool pickerOpen: false
    property string newContext: "Global"
    property string newKey: ""
    property string newAction: ""

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
                text: "Zed keymap: ~/.config/zed/keymap.json. After saving, restart Zed to apply."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Text {
                width: parent.width
                text: ZedKeys.status
                color: Theme.muted
                font.pixelSize: 11
                bottomPadding: 4
            }

            Repeater {
                model: ZedKeys.entries

                Rectangle {
                    required property var modelData
                    required property int index

                    width: col.width
                    height: 58
                    radius: 8
                    color: Qt.alpha(Theme.surface, 0.4)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        text: modelData.context === "" ? "Global" : modelData.context
                        color: Theme.muted
                        font.pixelSize: 10
                    }

                    Rectangle {
                        id: zKey
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        width: 170
                        height: 26
                        radius: 6
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.color: zKeyInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: zKeyInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: modelData.key
                            selectByMouse: true
                            clip: true
                            onEditingFinished: ZedKeys.setKey(modelData.section, modelData.key, text)
                        }
                    }

                    Rectangle {
                        id: zAction
                        anchors.left: zKey.right
                        anchors.leftMargin: 6
                        anchors.right: zPicker.left
                        anchors.rightMargin: 6
                        anchors.top: zKey.top
                        height: 26
                        radius: 6
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.color: zActionInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: zActionInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: modelData.action
                            selectByMouse: true
                            clip: true
                            onEditingFinished: ZedKeys.setAction(modelData.section, modelData.key, text)
                        }
                    }

                    Rectangle {
                        id: zPicker
                        anchors.right: zRemove.left
                        anchors.rightMargin: 6
                        anchors.top: zKey.top
                        width: 26
                        height: 26
                        radius: 6
                        color: zPickerMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.bg, 0.6)
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "▾"
                            color: Theme.accent
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: zPickerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pane.pickingRow = index
                                pane.pickerOpen = true
                            }
                        }
                    }

                    Rectangle {
                        id: zRemove
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: zKey.top
                        width: 26
                        height: 26
                        radius: 6
                        color: zRemoveMouse.containsMouse ? Qt.alpha(Theme.error, 0.25) : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: Theme.error
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: zRemoveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ZedKeys.remove(modelData.section, modelData.key)
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

            FontSelect {
                width: col.width
                label: "Context"
                value: pane.newContext
                families: ZedKeys.contexts()
                onSelected: (v) => pane.newContext = v
            }

            Text {
                text: "Key"
                color: Theme.fg
                font.pixelSize: 12
                topPadding: 4
            }

            Rectangle {
                width: col.width
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: zNewKey.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: zNewKey
                    anchors.fill: parent
                    anchors.margins: 7
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: pane.newKey
                    selectByMouse: true
                    clip: true
                    onTextEdited: pane.newKey = text
                }
            }

            Text {
                text: "Action"
                color: Theme.fg
                font.pixelSize: 12
                topPadding: 4
            }

            Row {
                width: col.width
                spacing: 6

                Rectangle {
                    width: parent.width - 36
                    height: 28
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.7)
                    border.color: zNewAction.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: zNewAction
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: pane.newAction
                        selectByMouse: true
                        clip: true
                        onTextEdited: pane.newAction = text
                    }
                }

                Rectangle {
                    width: 30
                    height: 28
                    radius: 7
                    color: zNewPicker.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.surface, 0.7)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "▾"
                        color: Theme.accent
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: zNewPicker
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pane.pickingRow = -2
                            pane.pickerOpen = true
                        }
                    }
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
                    color: zAdd.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Add"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: zAdd
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ZedKeys.add(pane.newContext, pane.newKey.trim(), pane.newAction.trim())
                            pane.newKey = ""
                            pane.newAction = ""
                        }
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: zSave.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: zSave
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ZedKeys.save()
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: zRevert.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Revert"
                        color: Theme.fg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: zRevert
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ZedKeys.reload()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: pane.pickerOpen
        onClicked: pane.pickerOpen = false
    }

    ActionPicker {
        visible: pane.pickerOpen
        anchors.centerIn: parent
        title: "Zed action"
        items: ZedKeys.actions
        current: pane.pickingRow === -2 ? pane.newAction
            : (ZedKeys.entries[pane.pickingRow] ? ZedKeys.entries[pane.pickingRow].action : "")
        onAccepted: (v) => {
            if (pane.pickingRow === -2)
                pane.newAction = v
            else if (ZedKeys.entries[pane.pickingRow])
                ZedKeys.setAction(ZedKeys.entries[pane.pickingRow].section,
                                  ZedKeys.entries[pane.pickingRow].key, v)
            pane.pickerOpen = false
            pane.pickingRow = -1
        }
        onCancelled: {
            pane.pickerOpen = false
            pane.pickingRow = -1
        }
    }
}