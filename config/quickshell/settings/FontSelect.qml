import QtQuick
import Quickshell
import qs

// Выбор шрифта: строка-кнопка + раскрывающийся список с фильтром.
Item {
    id: root

    property string label: ""
    property string value: ""
    property var families: []
    property bool open: false
    property string filter: ""

    signal selected(string family)

    implicitHeight: 20 + 34 + (open ? 208 : 0)

    function filtered() {
        const q = ("" + root.filter).toLowerCase()
        const out = []
        for (let i = 0; i < root.families.length; i++) {
            const f = root.families[i]
            if (q === "" || f.toLowerCase().indexOf(q) >= 0)
                out.push(f)
        }
        return out
    }

    Text {
        id: lbl
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.label
        color: Theme.fg
        font.pixelSize: 12
    }

    Rectangle {
        id: button
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: lbl.bottom
        anchors.topMargin: 4
        height: 30
        radius: 7
        color: Qt.alpha(Theme.surface, 0.7)
        border.color: root.open ? Theme.accent : Theme.border
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: arrow.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.value === "" ? "(default)" : root.value
            color: Theme.fg
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.open ? "▴" : "▾"
            color: Theme.accent
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.open = !root.open
                root.filter = ""
            }
        }
    }

    Rectangle {
        id: listBox
        visible: root.open
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: button.bottom
        anchors.topMargin: 4
        height: 200
        radius: 8
        color: Qt.alpha(Theme.bg, 0.98)
        border.color: Theme.border
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: Qt.alpha(Theme.surface, 0.8)
                border.color: filterInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: filterInput
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    text: root.filter
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.filter = text

                    Text {
                        visible: filterInput.text === ""
                        text: "Filter…"
                        color: Theme.muted
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - 32
                clip: true
                spacing: 1
                model: root.filtered()

                delegate: Rectangle {
                    required property string modelData

                    readonly property bool current: modelData === root.value

                    width: ListView.view.width
                    height: 26
                    radius: 5
                    color: current ? Qt.alpha(Theme.accent, 0.22)
                        : (itemMouse.containsMouse ? Theme.surface : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: current ? Theme.fg : Theme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selected(modelData)
                            root.open = false
                            root.filter = ""
                        }
                    }
                }
            }
        }
    }
}