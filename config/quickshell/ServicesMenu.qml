import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: UiState.panel === "services"
    implicitWidth: 380
    implicitHeight: 240
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    // OnDemand, а не Exclusive: иначе окно пароля polkit не получит клавиатуру
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool warpOn: false
    property bool zapretOn: false
    property bool warpBusy: false
    property bool zapretBusy: false

    function refresh() {
        warpCheck.running = true
        zapretCheck.running = true
    }

    function toggleWarp() {
        warpBusy = true
        warpToggle.command = ["warp-cli", "--accept-tos", warpOn ? "disconnect" : "connect"]
        warpToggle.running = true
    }

    function toggleZapret() {
        zapretBusy = true
        zapretToggle.command = ["systemctl", zapretOn ? "stop" : "start", "zapret2.service"]
        zapretToggle.running = true
    }

    onVisibleChanged: if (visible) { refresh(); scope.forceActiveFocus() }

    // Пока меню открыто, раз в 3 секунды перепроверяем состояние
    Timer { interval: 3000; repeat: true; running: root.visible; onTriggered: root.refresh() }
    // Небольшая пауза после переключения, чтобы служба успела сменить состояние
    Timer { id: recheck; interval: 1200; onTriggered: root.refresh() }

    // --- проверка состояния (код выхода 0 = включено) ---
    Process {
        id: warpCheck
        command: ["sh", "-c", "warp-cli --accept-tos status 2>/dev/null | grep -q 'Status update: Connected'"]
        onExited: (exitCode) => root.warpOn = (exitCode === 0)
    }
    Process {
        id: zapretCheck
        command: ["systemctl", "is-active", "--quiet", "zapret2.service"]
        onExited: (exitCode) => root.zapretOn = (exitCode === 0)
    }

    // --- переключение ---
    Process {
        id: warpToggle
        onExited: { root.warpBusy = false; recheck.restart() }
    }
    Process {
        id: zapretToggle
        onExited: { root.zapretBusy = false; recheck.restart() }
    }

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
                text: "Обход блокировок"
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
                x: 12; y: 58
                width: parent.width - 24
                spacing: 6

                ServiceRow {
                    width: parent.width
                    title: "Cloudflare WARP"
                    checked: root.warpOn
                    busy: root.warpBusy
                    onToggled: root.toggleWarp()
                }
                ServiceRow {
                    width: parent.width
                    title: "zapret2"
                    checked: root.zapretOn
                    busy: root.zapretBusy
                    onToggled: root.toggleZapret()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                text: "Super + Z или Esc — закрыть"
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
}
