import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 6

        Text {
            text: "Palette"
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: "Stage 3: 22 colour fields (hex input + picker) for the active theme."
            color: Theme.muted
            font.pixelSize: 12
        }

        Item { Layout.fillHeight: true }
    }
}