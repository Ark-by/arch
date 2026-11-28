import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Полноэкранное превью обоев из сети.
// Накрывает бар и все окна (слой Overlay), снизу — полоска «Назад / Скачать».
// Ничего не сохраняет: «Назад» просто закрывает превью, обои на диске не меняются.
PanelWindow {
    id: win

    visible: UiState.previewOpen
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wallpaper-preview"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property string tmpDir: "/tmp/qs-wallhaven"
    readonly property string wallDir: UiState.home + "/Pictures/Wallpapers"
    readonly property string ext: {
        const p = "" + UiState.previewRemote
        const i = p.lastIndexOf(".")
        return i > 0 ? p.substring(i + 1).toLowerCase() : "jpg"
    }
    readonly property string tmpFile: tmpDir + "/" + UiState.previewId + "." + ext
    readonly property string dstFile: wallDir + "/" + UiState.previewId + "." + ext

    property string status: ""
    property bool fetching: false
    property bool saving: false

    function close() {
        UiState.closePreview()
    }

    function save() {
        if (saving || UiState.previewSaved)
            return
        saving = true
        status = "Сохраняю…"
        saver.command = ["bash", "-c",
            "mkdir -p \"$1\" && if [ -s \"$2\" ]; then cp -f -- \"$2\" \"$3\"; else curl -fsSL --max-time 90 --retry 2 -o \"$3\" \"$4\"; fi",
            "sh", wallDir, tmpFile, dstFile, UiState.previewRemote]
        saver.running = true
    }

    onVisibleChanged: {
        if (visible) {
            scope.forceActiveFocus()
            status = ""
            saving = false
            if (UiState.previewLocal === "") {
                fetching = true
                fetcher.command = ["bash", "-c", "mkdir -p \"$1\" && curl -fsSL --max-time 90 --retry 2 -o \"$2\" \"$3\"",
                    "sh", tmpDir, tmpFile, UiState.previewRemote]
                fetcher.running = true
            }
        } else {
            fetching = false
        }
    }

    // скачивание полноразмера в /tmp (для показа и для последующего «Скачать»)
    Process {
        id: fetcher
        property var cmd: []
        command: cmd
        stderr: StdioCollector {
            onStreamFinished: {
                const t = ("" + this.text).trim()
                if (t !== "")
                    win.status = "Ошибка: " + t.slice(-90)
            }
        }
        onExited: (code) => {
            win.fetching = false
            if (code === 0) {
                UiState.previewLocal = win.tmpFile
                if (win.status.startsWith("Ошибка"))
                    win.status = ""
            } else if (win.status === "") {
                win.status = "Не удалось загрузить полноразмер (" + code + ")"
            }
        }
    }

    // сохранение в ~/Pictures/Wallpapers + применение
    Process {
        id: saver
        property var cmd: []
        command: cmd
        onExited: (code) => {
            win.saving = false
            if (code === 0) {
                UiState.setWallpaper(win.dstFile)
                UiState.previewSaved = true
                win.status = "Скачано: " + UiState.previewId + "." + win.ext
            } else {
                win.status = "Не удалось сохранить (" + code + ")"
            }
        }
    }

    Image {
        anchors.fill: parent
        source: UiState.previewLocal !== "" ? "file://" + UiState.previewLocal : UiState.previewThumb
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
    }

    // клик мимо полоски — закрыть
    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    // ---------- нижняя полоска ----------
    Rectangle {
        id: strip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        height: 52
        width: stripRow.implicitWidth + 28
        radius: 14
        color: Qt.alpha(Theme.bg, 0.92)
        border.color: Theme.accent
        border.width: 1

        Row {
            id: stripRow
            anchors.centerIn: parent
            spacing: 14

            // Назад
            Rectangle {
                width: 40
                height: 36
                radius: 9
                color: backMouse.containsMouse ? Theme.surface : "transparent"
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: Theme.fg
                    font.pixelSize: 18
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.close()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: UiState.previewResolution !== "" ? UiState.previewResolution : "—"
                    color: Theme.fg
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: win.status !== "" ? win.status : (win.fetching ? "Загружаю полноразмер…" : "")
                    color: win.status.startsWith("Ошибка") || win.status.startsWith("Не удалось") ? Theme.error : Theme.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: 220
                }
            }

            // Скачать / скачано
            Rectangle {
                width: 108
                height: 36
                radius: 9
                color: UiState.previewSaved
                    ? Qt.alpha(Theme.success, 0.25)
                    : (saveMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent)

                Text {
                    anchors.centerIn: parent
                    text: UiState.previewSaved ? "✓ Скачано" : (win.saving ? "…" : "⤓ Скачать")
                    color: UiState.previewSaved ? Theme.success : Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !win.saving && !UiState.previewSaved
                    onClicked: win.save()
                }
            }
        }
    }

    // Esc = назад (прозрачный слой, клики не перехватывает)
    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.close()
    }
}
