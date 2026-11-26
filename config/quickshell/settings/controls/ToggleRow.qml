import QtQuick
import Quickshell
import qs

Item {
    id: root

    property string label: ""
    property bool checked: false

    signal toggled(bool checked)

    implicitHeight: 40

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.fg
        font.pixelSize: 14
    }

    Rectangle {
        id: sw
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 24
        radius: 12
        color: root.checked ? Theme.accent : Theme.surface
        border.color: Theme.border
        border.width: 1

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: root.checked ? sw.width - width - 3 : 3
            color: root.checked ? Theme.bg : Theme.muted
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}