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
            // декодируем сразу под ширину экрана: 4K-файл не тратит память и время
            sourceSize.width: Math.round(parent.width)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
        }
    }
}
