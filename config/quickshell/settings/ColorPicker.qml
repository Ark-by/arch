import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Простой HSV-пикер: три слайдера + предпросмотр + hex.
Rectangle {
    id: root

    property color current: "#000000"

    signal accepted(color value)
    signal cancelled()

    radius: 12
    color: Qt.alpha(Theme.bg, 0.97)
    border.color: Theme.accent
    border.width: 1

    implicitWidth: 320
    implicitHeight: 268

    property real h: 0
    property real s: 0
    property real v: 0

    readonly property color preview: root.hsv2rgb(root.h, root.s, root.v)

    function rgb2hsv(r, g, b) {
        r /= 255; g /= 255; b /= 255
        const max = Math.max(r, g, b)
        const min = Math.min(r, g, b)
        const d = max - min
        let h = 0
        if (d !== 0) {
            if (max === r) h = ((g - b) / d) % 6
            else if (max === g) h = (b - r) / d + 2
            else h = (r - g) / d + 4
            h *= 60
            if (h < 0) h += 360
        }
        return { h: h, s: max === 0 ? 0 : d / max, v: max }
    }

    function hsv2rgb(h, s, v) {
        const c = v * s
        const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
        const m = v - c
        let r = 0, g = 0, b = 0
        if (h < 60) { r = c; g = x }
        else if (h < 120) { r = x; g = c }
        else if (h < 180) { g = c; b = x }
        else if (h < 240) { g = x; b = c }
        else if (h < 300) { r = x; b = c }
        else { r = c; b = x }
        return Qt.rgba(r + m, g + m, b + m, 1)
    }

    function load() {
        const c = rgb2hsv(root.current.r * 255, root.current.g * 255, root.current.b * 255)
        root.h = Math.round(c.h)
        root.s = Math.round(c.s * 100)
        root.v = Math.round(c.v * 100)
    }

    onCurrentChanged: load()
    Component.onCompleted: load()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 2

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Colour"
                color: Theme.fg
                font.pixelSize: 14
                font.bold: true
            }

            Rectangle {
                width: 60
                height: 22
                radius: 6
                color: root.preview
                border.color: Theme.border
                border.width: 1
            }
        }

        SliderRow {
            Layout.fillWidth: true
            label: "Hue"
            from: 0
            to: 360
            step: 1
            value: root.h
            onEdited: (x) => root.h = x
        }

        SliderRow {
            Layout.fillWidth: true
            label: "Saturation"
            suffix: "%"
            from: 0
            to: 100
            step: 1
            value: root.s
            onEdited: (x) => root.s = x
        }

        SliderRow {
            Layout.fillWidth: true
            label: "Value"
            suffix: "%"
            from: 0
            to: 100
            step: 1
            value: root.v
            onEdited: (x) => root.v = x
        }

        Text {
            text: ("" + root.preview).toUpperCase()
            color: Theme.muted
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 90
                height: 30
                radius: 8
                color: cancelMouse.containsMouse ? Theme.surface : "transparent"
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.fg
                    font.pixelSize: 12
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelled()
                }
            }

            Rectangle {
                width: 90
                height: 30
                radius: 8
                color: okMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    color: Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: okMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.accepted(root.preview)
                }
            }
        }
    }
}