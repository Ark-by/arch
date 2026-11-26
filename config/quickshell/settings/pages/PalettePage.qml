import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

    property string selectedBase: ""
    property var draft: null
    property string pickingKey: ""
    property string status: ""

    function loadDraft(base) {
        const t = ThemeStore.find(base)
        if (!t) {
            page.draft = null
            return
        }
        page.draft = JSON.parse(JSON.stringify(t))
    }

    function fields() {
        const out = []
        const d = page.draft
        if (!d)
            return out

        for (let i = 0; i < ThemeStore.baseKeys.length; i++) {
            const k = ThemeStore.baseKeys[i]
            if (d[k] !== undefined)
                out.push({ key: k, label: k, value: d[k] })
        }
        if (d.ansi) {
            for (let i = 0; i < d.ansi.length && i < 16; i++)
                out.push({ key: "ansi." + i, label: "ansi" + i, value: d.ansi[i] })
        }
        for (let i = 0; i < ThemeStore.semanticKeys.length; i++) {
            const k = ThemeStore.semanticKeys[i]
            if (d[k] !== undefined)
                out.push({ key: k, label: k, value: d[k] })
        }
        return out
    }

    function valueOf(key) {
        const d = page.draft
        if (!d)
            return "#000000"
        if (key.indexOf("ansi.") === 0) {
            const i = parseInt(key.substring(5))
            return (d.ansi && d.ansi[i]) ? d.ansi[i] : "#000000"
        }
        return d[key] || "#000000"
    }

    function setField(key, hex) {
        if (!page.draft)
            return
        const d = JSON.parse(JSON.stringify(page.draft))
        if (key.indexOf("ansi.") === 0) {
            const i = parseInt(key.substring(5))
            if (!d.ansi) d.ansi = []
            d.ansi[i] = hex
        } else {
            d[key] = hex
        }
        page.draft = d
    }

    function save() {
        if (!page.draft) { page.status = "Nothing to save"; return }
        ThemeStore.save(page.draft)
        if (page.selectedBase === ThemeStore.activeBase())
            ThemeStore.apply(page.selectedBase)
        page.status = "Saved " + page.selectedBase
    }

    Connections {
        target: ThemeStore
        function onSelectedChanged() {
            page.selectedBase = ThemeStore.selected
            page.loadDraft(page.selectedBase)
            page.status = ""
        }
        function onChanged() {
            if (page.draft === null)
                page.loadDraft(page.selectedBase)
        }
    }

    Component.onCompleted: {
        page.selectedBase = ThemeStore.selected !== "" ? ThemeStore.selected : ThemeStore.activeBase()
        page.loadDraft(page.selectedBase)
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
            spacing: 4

            Text {
                text: "Palette"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Edit the colours of a palette. Saving regenerates every app and applies the theme if it is active."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 4
            }

            // выбор темы
            Flow {
                width: col.width
                spacing: 6
                topPadding: 2
                bottomPadding: 6

                Repeater {
                    model: ThemeStore.themes

                    Rectangle {
                        required property var modelData

                        readonly property string base: ThemeStore._base(modelData)
                        readonly property bool active: base === page.selectedBase

                        width: Math.max(70, nameText.implicitWidth + 20)
                        height: 26
                        radius: 7
                        color: active ? Theme.accent : Theme.surface
                        border.color: active ? Theme.accent : Theme.border
                        border.width: 1

                        Text {
                            id: nameText
                            anchors.centerIn: parent
                            text: modelData.name
                            color: active ? Theme.bg : Theme.fg
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                page.selectedBase = base
                                page.loadDraft(base)
                                page.status = ""
                            }
                        }
                    }
                }
            }

            Repeater {
                model: page.fields()

                ColorField {
                    required property var modelData

                    width: col.width
                    label: modelData.label
                    hex: page.valueOf(modelData.key)
                    onEdited: (hex) => page.setField(modelData.key, hex)
                    onPickRequested: page.pickingKey = modelData.key
                }
            }

            Item { width: 1; height: 12 }

            Row {
                spacing: 8
                width: col.width

                Rectangle {
                    width: 100
                    height: 32
                    radius: 8
                    color: saveMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: Theme.bg
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.save()
                    }
                }

                Rectangle {
                    width: 100
                    height: 32
                    radius: 8
                    color: revertMouse.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Revert"
                        color: Theme.fg
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: revertMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            page.loadDraft(page.selectedBase)
                            page.status = "Reverted"
                        }
                    }
                }
            }

            Text {
                visible: page.status !== ""
                width: col.width
                text: page.status
                color: Theme.muted
                font.pixelSize: 11
                topPadding: 6
                wrapMode: Text.Wrap
            }
        }
    }

    // пикер поверх страницы
    Rectangle {
        visible: page.pickingKey !== ""

        anchors.fill: parent
        color: Qt.alpha("#000000", 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: page.pickingKey = ""
        }

        ColorPicker {
            anchors.centerIn: parent
            current: page.valueOf(page.pickingKey)

            onAccepted: (c) => {
                page.setField(page.pickingKey, ("" + c).toString())
                page.pickingKey = ""
            }
            onCancelled: page.pickingKey = ""
        }
    }
}