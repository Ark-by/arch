import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

    property string newKey: 'mainMod .. " + F1"'
    property int newAction: 0

    readonly property var catalog: [
        { name: "Terminal (kitty)",     dispatch: 'hl.dsp.exec_cmd("kitty")' },
        { name: "Browser (firefox)",    dispatch: 'hl.dsp.exec_cmd("firefox")' },
        { name: "Zed",                  dispatch: 'hl.dsp.exec_cmd("zeditor")' },
        { name: "File manager (yazi)",  dispatch: 'hl.dsp.exec_cmd("yazi")' },
        { name: "App launcher",         dispatch: 'hl.dsp.exec_cmd("qs ipc call ui launcher")' },
        { name: "Settings",             dispatch: 'hl.dsp.exec_cmd("qs ipc call settings open")' },
        { name: "Themes page",          dispatch: 'hl.dsp.exec_cmd("qs ipc call settings openPage themes")' },
        { name: "Wallpapers page",      dispatch: 'hl.dsp.exec_cmd("qs ipc call settings openPage wallpapers")' },
        { name: "Resources menu",       dispatch: 'hl.dsp.exec_cmd("qs ipc call ui monitor")' },
        { name: "Services menu",        dispatch: 'hl.dsp.exec_cmd("qs ipc call ui services")' },
        { name: "Close window",         dispatch: 'hl.dsp.window.close()' },
        { name: "Toggle floating",      dispatch: 'hl.dsp.window.float({ action = "toggle" })' },
        { name: "Pseudo tile",          dispatch: 'hl.dsp.window.pseudo()' }
    ]

    function actionNames() {
        const out = []
        for (let i = 0; i < page.catalog.length; i++)
            out.push(page.catalog[i].name)
        return out
    }

    function addBind() {
        const a = page.catalog[page.newAction]
        if (!a)
            return
        const key = ("" + page.newKey).trim()
        if (key === "")
            return
        KeyStore.add(key, a.dispatch, "Extra: " + a.name)
        KeyStore.status = "added " + a.name
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
            spacing: 2

            Text {
                text: "Keys"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Binds are read from ~/.config/hypr/keybinds.lua. Edit the key expression, disable a bind or remove it. Save applies hyprctl reload."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Text {
                width: parent.width
                text: KeyStore.status
                color: Theme.muted
                font.pixelSize: 11
                bottomPadding: 4
            }

            Repeater {
                model: KeyStore.binds

                Rectangle {
                    required property var modelData

                    width: col.width
                    height: 46
                    radius: 8
                    color: Qt.alpha(Theme.surface, modelData.enabled ? 0.4 : 0.15)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: comboField.left
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        text: modelData.desc
                        color: modelData.enabled ? Theme.fg : Theme.muted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 24
                        text: modelData.dispatch
                        color: Theme.muted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        width: comboField.x - 20
                    }

                    Rectangle {
                        id: comboField
                        anchors.right: actionsRow.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 230
                        height: 26
                        radius: 6
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.color: comboInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: comboInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: modelData.key
                            selectByMouse: true
                            clip: true
                            onEditingFinished: KeyStore.setKey(modelData.index, text)
                        }
                    }

                    Row {
                        id: actionsRow
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: modelData.enabled ? Qt.alpha(Theme.accent, 0.25) : Theme.surface
                            border.color: modelData.enabled ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.enabled ? "on" : "off"
                                color: modelData.enabled ? Theme.accent : Theme.muted
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KeyStore.setEnabled(modelData.index, !modelData.enabled)
                            }
                        }

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: removeMouse.containsMouse ? Qt.alpha(Theme.error, 0.25) : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: Theme.error
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: removeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KeyStore.remove(modelData.index)
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 14 }

            Text {
                text: "Add a bind"
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 4
            }

            FontSelect {
                width: parent.width
                label: "Action"
                value: page.catalog[page.newAction] ? page.catalog[page.newAction].name : ""
                families: page.actionNames()
                onSelected: (v) => {
                    for (let i = 0; i < page.catalog.length; i++)
                        if (page.catalog[i].name === v) { page.newAction = i; break }
                }
            }

            Text {
                text: "Key expression"
                color: Theme.fg
                font.pixelSize: 12
                topPadding: 4
            }

            Rectangle {
                width: parent.width
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: newKeyInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: newKeyInput
                    anchors.fill: parent
                    anchors.margins: 7
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: page.newKey
                    selectByMouse: true
                    clip: true
                    onTextEdited: page.newKey = text
                    onAccepted: page.addBind()
                }
            }

            Row {
                width: parent.width
                spacing: 8
                topPadding: 8

                Rectangle {
                    width: 120
                    height: 30
                    radius: 8
                    color: addMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Add bind"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.addBind()
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: saveMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: KeyStore.save()
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 8
                    color: revertMouse.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Revert"
                        color: Theme.fg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: revertMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            KeyStore.reload()
                            KeyStore.status = "reloaded from file"
                        }
                    }
                }
            }
        }
    }
}