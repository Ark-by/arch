import QtQuick
import Quickshell
import qs

// Модальный выбор действия из списка с фильтром.
// Ввод в фильтр + Enter — произвольное значение.
Rectangle {
    id: root

    property string title: "Action"
    property var items: []
    property string current: ""
    property string filter: ""

    signal accepted(string value)
    signal cancelled()

    width: 420
    height: 380
    radius: 12
    color: Qt.alpha(Theme.bg, 0.98)
    border.color: Theme.accent
    border.width: 1

    function filtered() {
        const q = ("" + root.filter).toLowerCase()
        const out = []
        for (let i = 0; i < root.items.length; i++) {
            const it = root.items[i]
            if (q === "" || it.toLowerCase().indexOf(q) >= 0)
                out.push(it)
        }
        return out
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Text {
            text: root.title
            color: Theme.fg
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 30
            radius: 7
            color: Qt.alpha(Theme.surface, 0.8)
            border.color: filterInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            TextInput {
                id: filterInput
                anchors.fill: parent
                anchors.margins: 7
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                text: root.filter
                selectByMouse: true
                clip: true
                focus: true
                onTextChanged: root.filter = text
                Keys.onReturnPressed: {
                    const v = ("" + root.filter).trim()
                    if (v !== "") {
                        root.accepted(v)
                    }
                }
                Keys.onEscapePressed: root.cancelled()

                Text {
                    visible: filterInput.text === ""
                    text: "Filter or type a custom value, Enter to apply"
                    color: Theme.muted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        ListView {
            width: parent.width
            height: parent.height - 110
            clip: true
            spacing: 1
            model: root.filtered()

            delegate: Rectangle {
                required property string modelData

                readonly property bool current: modelData === root.current

                width: ListView.view.width
                height: 26
                radius: 5
                color: current ? Qt.alpha(Theme.accent, 0.22)
                    : (rowMouse.containsMouse ? Theme.surface : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: current ? Theme.fg : Theme.muted
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.accepted(modelData)
                }
            }
        }

        Rectangle {
            width: 100
            height: 30
            radius: 8
            color: cancelMouse.containsMouse ? Theme.surface : "transparent"
            border.color: Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: Theme.fg
                font.pixelSize: 11
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cancelled()
            }
        }
    }
}