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
            text: "Wallpapers"
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: "Stage 4: preview grid from ~/Pictures/Wallpapers, Wallhaven download, trash."
            color: Theme.muted
            font.pixelSize: 12
        }

        Item { Layout.fillHeight: true }
    }
}