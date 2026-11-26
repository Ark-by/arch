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
            text: "Keys"
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: "Stage 6: list of binds, edit combo (text), add from actions, delete, reset."
            color: Theme.muted
            font.pixelSize: 12
        }

        Item { Layout.fillHeight: true }
    }
}