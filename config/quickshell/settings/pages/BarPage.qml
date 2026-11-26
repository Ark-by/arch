import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import "../controls"

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 4

        Text {
            text: "Bar"
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: "Panel height, transparency and placement."
            color: Theme.muted
            font.pixelSize: 12
            Layout.bottomMargin: 8
        }

        SliderRow {
            Layout.fillWidth: true
            label: "Height"
            suffix: " px"
            from: 24
            to: 64
            step: 1
            value: Settings.get("bar.height", 36)
            onEdited: (v) => Settings.set("bar.height", Math.round(v))
        }

        SliderRow {
            Layout.fillWidth: true
            label: "Opacity"
            suffix: ""
            from: 0.3
            to: 1
            step: 0.05
            value: Settings.get("bar.opacity", 0.7)
            onEdited: (v) => Settings.set("bar.opacity", Math.round(v * 100) / 100)
        }

        SelectRow {
            Layout.fillWidth: true
            label: "Position"
            options: ["top", "bottom"]
            value: Settings.get("bar.position", "top")
            onSelected: (v) => Settings.set("bar.position", v)
        }

        ToggleRow {
            Layout.fillWidth: true
            label: "Hide in fullscreen"
            checked: Settings.get("bar.hideFullscreen", false)
            onToggled: (v) => Settings.set("bar.hideFullscreen", v)
        }

        Item { Layout.fillHeight: true }

        Text {
            text: "Note: height and opacity apply live. Position and fullscreen mode are stored for stage 2."
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}