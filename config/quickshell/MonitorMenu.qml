import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: UiState.panel === "monitor"
    implicitWidth: 440
    implicitHeight: col.implicitHeight + 112
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property var gpu: SysInfo.extra.gpu || null

    onVisibleChanged: if (visible) scope.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.alpha(Theme.bg, 0.9)
        border.color: Theme.accent
        border.width: 1

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: UiState.panel = ""

            Text {
                x: 20; y: 16
                text: "Монитор ресурсов"
                color: Theme.fg
                font.pixelSize: 18
                font.bold: true
            }

            IconButton {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                text: "\uf00d"
                hoverColor: Theme.error
                onClicked: UiState.panel = ""
            }

            Column {
                id: col
                x: 20; y: 58
                width: parent.width - 40
                spacing: 10

                MetricRow {
                    width: parent.width
                    title: "Процессор"
                    valueText: Math.round(SysInfo.cpu) + "%"
                        + (SysInfo.extra.cpu_temp != null ? "  ·  " + SysInfo.extra.cpu_temp + " °C" : "")
                    percent: SysInfo.cpu
                    showGraph: true
                    history: SysInfo.cpuHistory
                }

                MetricRow {
                    width: parent.width
                    title: "Память"
                    valueText: SysInfo.memUsed.toFixed(1) + " / " + SysInfo.memTotal.toFixed(1)
                        + " ГиБ  ·  " + Math.round(SysInfo.memPct) + "%"
                    percent: SysInfo.memPct
                    showGraph: true
                    history: SysInfo.memHistory
                }

                MetricRow {
                    width: parent.width
                    visible: SysInfo.swapTotal > 0
                    title: "Подкачка"
                    valueText: SysInfo.swapUsed.toFixed(1) + " / " + SysInfo.swapTotal.toFixed(1) + " ГиБ"
                    percent: SysInfo.swapPct
                }

                MetricRow {
                    width: parent.width
                    visible: root.gpu !== null
                    title: "Видеокарта"
                    valueText: root.gpu ? root.gpu.util + "%" + (root.gpu.temp != null ? "  ·  " + root.gpu.temp + " °C" : "") : ""
                    percent: root.gpu ? root.gpu.util : 0
                }

                MetricRow {
                    width: parent.width
                    visible: root.gpu !== null && root.gpu.mem_total > 0
                    title: "Видеопамять"
                    valueText: root.gpu && root.gpu.mem_total > 0
                        ? (root.gpu.mem_used / 1024).toFixed(1) + " / " + (root.gpu.mem_total / 1024).toFixed(1) + " ГиБ" : ""
                    percent: root.gpu && root.gpu.mem_total > 0 ? 100 * root.gpu.mem_used / root.gpu.mem_total : 0
                }

                MetricRow {
                    width: parent.width
                    visible: SysInfo.extra.disk_total_kb != null
                    title: "Диск /"
                    valueText: SysInfo.extra.disk_total_kb != null
                        ? (SysInfo.extra.disk_used_kb / 1048576).toFixed(0) + " / "
                          + (SysInfo.extra.disk_total_kb / 1048576).toFixed(0) + " ГиБ" : ""
                    percent: SysInfo.extra.disk_pct != null ? SysInfo.extra.disk_pct : 0
                }

                Item {
                    width: parent.width
                    height: 24
                    Text { text: "Сеть"; color: Theme.fg; font.pixelSize: 14 }
                    Text {
                        anchors.right: parent.right
                        text: "↓ " + SysInfo.fmtSpeed(SysInfo.netDown) + "      ↑ " + SysInfo.fmtSpeed(SysInfo.netUp)
                        color: Theme.muted
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 8
                    color: btopMa.containsMouse ? Theme.surface : "transparent"
                    border.color: Theme.muted
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Подробнее в btop"
                        color: Theme.fg
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: btopMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { UiState.panel = ""; Quickshell.execDetached(["kitty", "btop"]) }
                    }
                }
            }
        }
    }
}
