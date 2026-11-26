import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    id: root

    property string label: ""
    property string suffix: ""
    property real from: 0
    property real to: 1
    property real step: 0.01
    property real value: 0

    signal edited(real value)

    implicitHeight: 54

    // _v — «живое» значение; value остаётся биндингом наружу
    property real _v: value
    onValueChanged: _v = value

    function _clamp(v) {
        return Math.max(root.from, Math.min(root.to, v))
    }

    function _snap(v) {
        const stepped = Math.round((v - root.from) / root.step) * root.step + root.from
        return Math.round(root._clamp(stepped) * 1000) / 1000
    }

    function _update(x) {
        const t = Math.max(0, Math.min(1, x / track.width))
        root._v = root._snap(root.from + t * (root.to - root.from))
        root.edited(root._v)
    }

    Text {
        id: lbl
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.label
        color: Theme.fg
        font.pixelSize: 14
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: (Math.round(root._v * 100) / 100) + root.suffix
        color: Theme.accent
        font.pixelSize: 14
        font.bold: true
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: lbl.bottom
        anchors.topMargin: 10
        height: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            width: track.width * ((root._v - root.from) / (root.to - root.from))
            height: parent.height
            radius: 3
            color: Theme.accent
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: Theme.accent
            border.color: Theme.bg
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, track.width * ((root._v - root.from) / (root.to - root.from)) - width / 2))
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -12
            anchors.bottomMargin: -12
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => root._update(m.x)
            onPositionChanged: (m) => { if (pressed) root._update(m.x) }
        }
    }
}