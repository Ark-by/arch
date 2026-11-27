import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

    property string tab: "hyprland"
    property string newKey: 'mainMod .. " + F1"'
    property string newAction: ""
    property string appKey: ""
    property string appAction: ""
    property int newActionIndex: 0
    property int pickingIndex: -1
    property string pickingField: "action"
    property bool pickerOpen: false
    property int zedPickingRow: -1
    property bool zedPickerOpen: false
    property string zedNewContext: "Global"
    property string zedNewKey: ""
    property string zedNewAction: ""
    property string yaziNewOn: ""
    property string yaziNewRun: ""
    property string newContext: "common"

    readonly property var tabs: [
        { id: "hyprland", label: "Hyprland" },
        { id: "kitty", label: "kitty" },
        { id: "cmus", label: "cmus" },
        { id: "zed", label: "zed" },
        { id: "yazi", label: "yazi" }
    ]

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

    function isHypr() {
        return page.tab === "hyprland"
    }

    function isApp() {
        return page.tab === "kitty" || page.tab === "cmus"
    }

    function isExtra() {
        return page.tab === "zed" || page.tab === "yazi"
    }

    function selectTab(id) {
        page.tab = id
        if (id === "kitty" || id === "cmus") {
            AppKeys.targetId = id
            AppKeys.reload()
        } else if (id === "zed") {
            ZedKeys.reload()
        } else if (id === "yazi") {
            YaziKeys.reload()
        }
    }

    function addHypr() {
        const a = page.catalog[page.newActionIndex]
        const key = ("" + page.newKey).trim()
        if (!a || key === "")
            return
        KeyStore.add(key, a.dispatch, "Extra: " + a.name)
        KeyStore.status = "added " + a.name
    }

    function pickAction(index) {
        page.pickingIndex = index
        page.pickingField = "action"
        page.pickerOpen = true
    }

    function currentAction(lineIndex) {
        for (let i = 0; i < AppKeys.entries.length; i++)
            if (AppKeys.entries[i].index === lineIndex)
                return AppKeys.entries[i].action
        return ""
    }

    function applyPicked(value) {
        if (page.pickingIndex === -2) {
            page.appAction = value
        } else if (page.pickingIndex >= 0) {
            if (page.pickingField === "context")
                AppKeys.setContext(page.pickingIndex, value)
            else
                AppKeys.setAction(page.pickingIndex, value)
        }
        page.pickingIndex = -1
        page.pickingField = "action"
        page.pickerOpen = false
    }

    function pickerItems() {
        if (page.pickingField === "context")
            return AppKeys.cmusContexts
        return page.tab === "kitty" ? KittyActions.actions : CmusCommands.commands
    }

    function addApp() {
        const k = ("" + page.appKey).trim()
        const a = ("" + page.appAction).trim()
        if (k === "" || a === "")
            return
        AppKeys.add(k, a, page.newContext, "")
        AppKeys.status = "added " + k
    }

    function saveCurrent() {
        if (page.isHypr())
            KeyStore.save()
        else
            AppKeys.save()
    }

    function revertCurrent() {
        if (page.isHypr())
            KeyStore.reload()
        else
            AppKeys.reload()
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
                text: "Hyprland binds live in keybinds.lua. kitty and cmus use their own config files."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Row {
                spacing: 6
                bottomPadding: 6

                Repeater {
                    model: page.tabs

                    Rectangle {
                        required property var modelData

                        readonly property bool active: modelData.id === page.tab

                        width: Math.max(84, tabText.implicitWidth + 24)
                        height: 28
                        radius: 7
                        color: active ? Theme.accent : Qt.alpha(Theme.surface, 0.6)
                        border.color: active ? Theme.accent : Theme.border
                        border.width: 1

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: active ? Theme.bg : Theme.fg
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.selectTab(modelData.id)
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: page.isHypr() ? KeyStore.status : (page.isApp() ? AppKeys.status : (page.tab === "zed" ? ZedKeys.status : YaziKeys.status))
                color: Theme.muted
                font.pixelSize: 11
                bottomPadding: 4
            }

            // ---------- Hyprland ----------
            Column {
                width: col.width
                visible: page.isHypr()
                spacing: 2

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
                            width: Math.max(0, comboField.x - 20)
                        }

                        Rectangle {
                            id: comboField
                            anchors.right: actionsRow.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 220
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
            }

            // ---------- kitty / cmus ----------
            Column {
                width: col.width
                visible: page.isApp()
                spacing: 2

                Repeater {
                    model: AppKeys.entries

                    Rectangle {
                        required property var modelData

                        width: col.width
                        height: 46
                        radius: 8
                        color: Qt.alpha(Theme.surface, modelData.enabled ? 0.4 : 0.15)
                        border.color: Theme.border
                        border.width: 1

                        Rectangle {
                            id: contextBtn
                            visible: page.tab === "cmus"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 88
                            height: 26
                            radius: 6
                            color: Qt.alpha(Theme.bg, 0.6)
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: ctxArrow.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.context === "" ? "—" : modelData.context
                                color: Theme.fg
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                id: ctxArrow
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▾"
                                color: Theme.accent
                                font.pixelSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.pickingIndex = modelData.index
                                    page.pickingField = "context"
                                    page.pickerOpen = true
                                }
                            }
                        }

                        Rectangle {
                            id: keyField
                            anchors.left: contextBtn.visible ? contextBtn.right : parent.left
                            anchors.leftMargin: contextBtn.visible ? 6 : 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: contextBtn.visible ? 120 : 150
                            height: 26
                            radius: 6
                            color: Qt.alpha(Theme.bg, 0.6)
                            border.color: appKeyInput.activeFocus ? Theme.accent : Theme.border
                            border.width: 1

                            TextInput {
                                id: appKeyInput
                                anchors.fill: parent
                                anchors.margins: 6
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                text: modelData.key
                                selectByMouse: true
                                clip: true
                                onEditingFinished: AppKeys.setKey(modelData.index, text)
                            }
                        }

                        Rectangle {
                            id: actionField
                            anchors.left: keyField.right
                            anchors.leftMargin: 8
                            anchors.right: pickerBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            radius: 6
                            color: Qt.alpha(Theme.bg, 0.6)
                            border.color: appActionInput.activeFocus ? Theme.accent : Theme.border
                            border.width: 1

                            TextInput {
                                id: appActionInput
                                anchors.fill: parent
                                anchors.margins: 6
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                text: modelData.action
                                selectByMouse: true
                                clip: true
                                onEditingFinished: AppKeys.setAction(modelData.index, text)
                            }
                        }

                        Rectangle {
                            id: pickerBtn
                            anchors.right: appActions.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 26
                            radius: 6
                            color: pickerMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.bg, 0.6)
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "▾"
                                color: Theme.accent
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: pickerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.pickAction(modelData.index)
                            }
                        }

                        Row {
                            id: appActions
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
                                    onClicked: AppKeys.setEnabled(modelData.index, !modelData.enabled)
                                }
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 6
                                color: appRemove.containsMouse ? Qt.alpha(Theme.error, 0.25) : "transparent"
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.error
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: appRemove
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AppKeys.remove(modelData.index)
                                }
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

            // Hyprland: действие из каталога
            Column {
                width: col.width
                visible: page.isHypr()
                spacing: 4

                FontSelect {
                    width: col.width
                    label: "Action"
                    value: page.catalog[page.newActionIndex] ? page.catalog[page.newActionIndex].name : ""
                    families: page.actionNames()
                    onSelected: (v) => {
                        for (let i = 0; i < page.catalog.length; i++)
                            if (page.catalog[i].name === v) { page.newActionIndex = i; break }
                    }
                }

                Text {
                    text: "Key expression"
                    color: Theme.fg
                    font.pixelSize: 12
                    topPadding: 4
                }

                Rectangle {
                    width: col.width
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
                        onAccepted: page.addHypr()
                    }
                }
            }

            // kitty/cmus: ключ + команда
            Column {
                width: col.width
                visible: page.isApp()
                spacing: 4

                FontSelect {
                    width: col.width
                    visible: page.tab === "cmus"
                    label: "Context"
                    value: page.newContext
                    families: AppKeys.cmusContexts
                    onSelected: (v) => page.newContext = v
                }

                Text {
                    text: page.tab === "kitty" ? "Kitty key (e.g. ctrl+shift+t)" : "cmus key (e.g. x)"
                    color: Theme.fg
                    font.pixelSize: 12
                }

                Rectangle {
                    width: col.width
                    height: 28
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.7)
                    border.color: appNewKey.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: appNewKey
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: page.appKey
                        selectByMouse: true
                        clip: true
                        onTextEdited: page.appKey = text
                    }
                }

                Text {
                    text: page.tab === "kitty" ? "Kitty action (e.g. new_tab_with_cwd)" : "cmus command (e.g. player-play)"
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
                        border.color: appNewAction.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: appNewAction
                            anchors.fill: parent
                            anchors.margins: 7
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: page.appAction
                            selectByMouse: true
                            clip: true
                            onTextEdited: page.appAction = text
                            onAccepted: page.addApp()
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 28
                        radius: 7
                        color: pickNewMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.surface, 0.7)
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "▾"
                            color: Theme.accent
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: pickNewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                page.pickingField = "action"
                                page.pickingIndex = -2
                                page.pickerOpen = true
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 8 }

            Row {
                width: col.width
                spacing: 8
                topPadding: 4

                Rectangle {
                    width: 110
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
                        onClicked: page.isHypr() ? page.addHypr() : page.addApp()
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
                        onClicked: page.saveCurrent()
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
                        onClicked: page.revertCurrent()
                    }
                }
            }

            // ---------- zed ----------
            Column {
                width: col.width
                visible: page.tab === "zed"
                spacing: 2

                Text {
                    width: parent.width
                    text: ZedKeys.status
                    color: Theme.muted
                    font.pixelSize: 11
                    bottomPadding: 4
                }

                Text {
                    visible: ZedKeys.entries.length === 0
                    width: parent.width
                    text: "No bindings yet. Choose a context, a key and an action below, press Add, then Save."
                    color: Theme.muted
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    bottomPadding: 6
                }

                ListView {
                    width: col.width
                    height: Math.min(380, Math.max(140, ZedKeys.entries.length * 60))
                    clip: true
                    spacing: 2
                    model: ZedKeys.entries

                    delegate: Rectangle {
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
                                    page.zedPickingRow = index
                                    page.zedPickerOpen = true
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
                    text: "Add a Zed binding"
                    color: Theme.accent
                    font.pixelSize: 14
                    font.bold: true
                    bottomPadding: 4
                }

                FontSelect {
                    width: col.width
                    label: "Context"
                    value: page.zedNewContext
                    families: ZedKeys.contexts()
                    onSelected: (v) => page.zedNewContext = v
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
                    border.color: zNewKeyInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: zNewKeyInput
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: page.zedNewKey
                        selectByMouse: true
                        clip: true
                        onTextEdited: page.zedNewKey = text
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
                        border.color: zNewActionInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: zNewActionInput
                            anchors.fill: parent
                            anchors.margins: 7
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            text: page.zedNewAction
                            selectByMouse: true
                            clip: true
                            onTextEdited: page.zedNewAction = text
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
                                page.zedPickingRow = -2
                                page.zedPickerOpen = true
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
                        color: zAddBtn.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            color: Theme.bg
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: zAddBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ZedKeys.add(page.zedNewContext, page.zedNewKey.trim(), page.zedNewAction.trim())
                                page.zedNewKey = ""
                                page.zedNewAction = ""
                            }
                        }
                    }

                    Rectangle {
                        width: 100
                        height: 30
                        radius: 8
                        color: zSaveBtn.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: Theme.bg
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: zSaveBtn
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
                        color: zRevertBtn.containsMouse ? Theme.surface : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Revert"
                            color: Theme.fg
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: zRevertBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ZedKeys.reload()
                        }
                    }
                }
            }

            // ---------- yazi ----------
            Column {
                width: col.width
                visible: page.tab === "yazi"
                spacing: 2

                Text {
                    width: parent.width
                    text: YaziKeys.status
                    color: Theme.muted
                    font.pixelSize: 11
                    bottomPadding: 4
                }

                ListView {
                    width: col.width
                    height: Math.min(420, Math.max(160, YaziKeys.entries.length * 44))
                    clip: true
                    spacing: 2
                    model: YaziKeys.entries

                    delegate: Rectangle {
                        required property var modelData

                        readonly property bool mine: modelData.source === "user"

                        width: ListView.view.width
                        height: 40
                        radius: 8
                        color: mine ? Qt.alpha(Theme.surface, 0.45) : Qt.alpha(Theme.surface, 0.18)
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            id: yBadge
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            text: mine ? "yours" : "built-in"
                            color: mine ? Theme.accent : Theme.muted
                            font.pixelSize: 9
                        }

                        Rectangle {
                            id: yOnBox
                            visible: mine
                            anchors.left: yBadge.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 130
                            height: 26
                            radius: 6
                            color: Qt.alpha(Theme.bg, 0.6)
                            border.color: Theme.border
                            border.width: 1

                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 5
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                text: modelData.on
                                selectByMouse: true
                                clip: true
                                onEditingFinished: YaziKeys.setOn(modelData.index, text)
                            }
                        }

                        Text {
                            id: yOnLabel
                            visible: !mine
                            anchors.left: yBadge.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 130
                            text: modelData.on
                            color: Theme.muted
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: yRunBox
                            visible: mine
                            anchors.left: yOnBox.right
                            anchors.leftMargin: 6
                            anchors.right: yRemove.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            radius: 6
                            color: Qt.alpha(Theme.bg, 0.6)
                            border.color: Theme.border
                            border.width: 1

                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 5
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                text: modelData.run
                                selectByMouse: true
                                clip: true
                                onEditingFinished: YaziKeys.setRun(modelData.index, text)
                            }
                        }

                        Text {
                            id: yRunLabel
                            visible: !mine
                            anchors.left: yOnLabel.right
                            anchors.leftMargin: 6
                            anchors.right: yRemove.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.run + (modelData.desc !== "" ? "  —  " + modelData.desc : "")
                            color: Theme.muted
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: yRemove
                            visible: mine
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
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
                                onClicked: YaziKeys.remove(modelData.index)
                            }
                        }
                    }
                }

                Item { width: 1; height: 12 }

                Text {
                    text: "Add your own binding"
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
                    border.color: yNewOnInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: yNewOnInput
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: page.yaziNewOn
                        selectByMouse: true
                        clip: true
                        onTextEdited: page.yaziNewOn = text
                    }
                }

                Text {
                    text: "Run (yazi command)"
                    color: Theme.fg
                    font.pixelSize: 12
                    topPadding: 4
                }

                Rectangle {
                    width: col.width
                    height: 28
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.7)
                    border.color: yNewRunInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: yNewRunInput
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: page.yaziNewRun
                        selectByMouse: true
                        clip: true
                        onTextEdited: page.yaziNewRun = text
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
                        color: yAddBtn.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            color: Theme.bg
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: yAddBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                YaziKeys.add(page.yaziNewOn, page.yaziNewRun, "")
                                page.yaziNewOn = ""
                                page.yaziNewRun = ""
                            }
                        }
                    }

                    Rectangle {
                        width: 100
                        height: 30
                        radius: 8
                        color: ySaveBtn.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: Theme.bg
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: ySaveBtn
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
                        color: yRevertBtn.containsMouse ? Theme.surface : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Revert"
                            color: Theme.fg
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: yRevertBtn
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

    // ---------- выбор действия ----------
    MouseArea {
        anchors.fill: parent
        visible: page.pickerOpen
        onClicked: {
            page.pickerOpen = false
            page.pickingIndex = -1
        }
    }

    ActionPicker {
        visible: page.pickerOpen
        anchors.centerIn: parent
        title: page.pickingField === "context" ? "cmus context" : (page.tab === "kitty" ? "kitty action" : "cmus command")
        items: page.pickerItems()
        current: page.pickingField === "context" ? (AppKeys.entryAt(page.pickingIndex) ? AppKeys.entryAt(page.pickingIndex).context : "") : (page.pickingIndex === -2 ? page.appAction : page.currentAction(page.pickingIndex))
        onAccepted: (v) => page.applyPicked(v)
        onCancelled: {
            page.pickerOpen = false
            page.pickingIndex = -1
        }
    }
    // ---------- выбор действия для Zed ----------
    MouseArea {
        anchors.fill: parent
        visible: page.zedPickerOpen
        onClicked: {
            page.zedPickerOpen = false
            page.zedPickingRow = -1
        }
    }

    ActionPicker {
        visible: page.zedPickerOpen
        anchors.centerIn: parent
        title: "Zed action"
        items: ZedKeys.actions
        current: page.zedPickingRow === -2 ? page.zedNewAction
            : (ZedKeys.entries[page.zedPickingRow] ? ZedKeys.entries[page.zedPickingRow].action : "")
        onAccepted: (v) => {
            if (page.zedPickingRow === -2) {
                page.zedNewAction = v
            } else if (ZedKeys.entries[page.zedPickingRow]) {
                ZedKeys.setAction(ZedKeys.entries[page.zedPickingRow].section,
                                  ZedKeys.entries[page.zedPickingRow].key, v)
            }
            page.zedPickerOpen = false
            page.zedPickingRow = -1
        }
        onCancelled: {
            page.zedPickerOpen = false
            page.zedPickingRow = -1
        }
    }
}
