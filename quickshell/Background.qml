import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "qs-bg"
        color: Theme.bg

        Image {
            anchors.fill: parent
            source: UiState.wallpaper ? "file://" + UiState.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
