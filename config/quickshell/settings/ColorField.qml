import QtQuick
import Quickshell
import qs

// Строка палитры: имя, образец цвета, hex-поле.
Item {
    id: root

    property string label: ""
    property string hex: "#000000"

    signal edited(string hex)
    signal pickRequested()

    implicitHeight: 32

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 128
        text: root.label
        color: Theme.fg
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    Rectangle {
        id: swatch
        anchors.left: parent.left
        anchors.leftMargin: 132
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 22
        radius: 6
        color: root.hex
        border.color: Theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pickRequested()
        }
    }

    Rectangle {
        anchors.left: swatch.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        radius: 6
        color: Qt.alpha(Theme.surface, 0.7)
        border.color: input.activeFocus ? Theme.accent : Theme.border
        border.width: 1

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            text: root.hex
            selectByMouse: true

            function normalize(s) {
                const m = ("" + s).trim().match(/^#?([0-9a-fA-F]{6})$/)
                return m ? "#" + m[1].toLowerCase() : ""
            }

            onEditingFinished: {
                const n = normalize(text)
                if (n !== "") {
                    text = n
                    root.edited(n)
                } else {
                    text = root.hex
                }
            }
        }
    }
}