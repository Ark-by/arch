import QtQuick
import Quickshell
import qs

Item {
    id: root

    property string label: ""
    property var options: []
    property string value: ""

    signal selected(string value)

    implicitHeight: 40

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.fg
        font.pixelSize: 14
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: root.options

            Rectangle {
                required property string modelData
                readonly property bool active: modelData === root.value

                width: Math.max(64, opt.implicitWidth + 20)
                height: 30
                radius: 8
                color: active ? Theme.accent : Theme.surface
                border.color: active ? Theme.accent : Theme.border
                border.width: 1

                Text {
                    id: opt
                    anchors.centerIn: parent
                    text: modelData
                    color: active ? Theme.bg : Theme.fg
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData)
                }
            }
        }
    }
}