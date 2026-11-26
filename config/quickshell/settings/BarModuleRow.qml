import QtQuick
import Quickshell
import qs

// Строка списка модулей: имя, порядок (вверх/вниз), вкл/выкл.
Item {
    id: root

    property string label: ""
    property bool enabled: true
    property bool isFirst: false
    property bool isLast: false

    signal moveUp()
    signal moveDown()
    signal toggled()

    implicitHeight: 34

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.enabled ? Theme.fg : Theme.muted
        font.pixelSize: 13
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: ["\u2191", "\u2193"]

            Rectangle {
                required property string modelData
                required property int index

                readonly property bool inactive: index === 0 ? root.isFirst : root.isLast

                width: 24
                height: 24
                radius: 6
                color: arrowMouse.containsMouse && !inactive ? Theme.surface : "transparent"
                border.color: Theme.border
                border.width: 1
                opacity: inactive ? 0.25 : 1

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: Theme.fg
                    font.pixelSize: 12
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !parent.inactive
                    cursorShape: Qt.PointingHandCursor
                    onClicked: index === 0 ? root.moveUp() : root.moveDown()
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 22
            radius: 11
            color: root.enabled ? Theme.accent : Theme.surface
            border.color: Theme.border
            border.width: 1

            Rectangle {
                width: 16
                height: 16
                radius: 8
                y: 2
                x: root.enabled ? parent.width - width - 3 : 3
                color: root.enabled ? Theme.bg : Theme.muted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }
    }
}