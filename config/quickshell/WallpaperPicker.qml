import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: UiState.panel === "wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                pageInput.forceActiveFocus()
                pageInput.selectAll()
            })
        }
    }
    implicitWidth: 820
    implicitHeight: 520

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"

    // Состояние загрузки
    property string downloadStatus: "Выбери обои или скачай новую страницу Wallhaven"
    property string downloadOutput: ""

    // Запуск загрузчика
    function startDownload() {
        const page = pageInput.text.trim()

        if (!/^[1-9][0-9]*$/.test(page)) {
            downloadStatus = "Введи корректный номер страницы"
            return
        }

        if (downloadProcess.running)
            return

        downloadOutput = ""
        downloadStatus = "Загружаю страницу " + page + "..."

        downloadProcess.command = [
            "/usr/bin/bash",
            UiState.home + "/.local/bin/wallhaven-download.sh",
            page
        ]

        downloadProcess.running = true
    }

    // Процесс загрузки
    Process {
        id: downloadProcess

        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                root.downloadOutput = this.text
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.downloadOutput += "\n" + this.text
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.downloadStatus = "Загрузка завершена!"
            } else {
                root.downloadStatus = "Ошибка загрузки (код " + exitCode + ")"
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: 16
        color: Qt.alpha(Theme.bg, 0.8)

        border.color: Theme.accent
        border.width: 1

        Keys.onEscapePressed: UiState.panel = ""

        // Поле выбора страницы и кнопка
        Row {
            id: controls

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 12

            height: 36
            spacing: 10

            Text {
                text: "Страница Wallhaven"

                color: Theme.fg
                font.pixelSize: 14

                height: 36
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 85
                height: 36
                radius: 7

                color: Qt.alpha(Theme.bg, 0.95)
                border.color: Theme.accent
                border.width: 1

                TextInput {
                    id: pageInput

                    focus: root.visible

                    anchors.fill: parent
                    anchors.margins: 8

                    text: "14"

                    color: Theme.fg
                    font.pixelSize: 15

                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter

                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly

                    validator: IntValidator {
                        bottom: 1
                        top: 100000
                    }

                    Keys.onReturnPressed: root.startDownload()
                }
            }

            Rectangle {
                id: downloadButton

                width: 125
                height: 36

                radius: 7

                color: downloadProcess.running
                    ? "#555555"
                    : downloadMouse.containsMouse
                        ? Qt.darker(Theme.accent, 1.15)
                        : Theme.accent

                Text {
                    anchors.centerIn: parent

                    text: downloadProcess.running
                        ? "Загрузка..."
                        : "Скачать"

                    color: Theme.bg
                    font.pixelSize: 14
                }

                MouseArea {
                    id: downloadMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: !downloadProcess.running

                    onClicked: root.startDownload()
                }
            }
        }

        // Статус загрузки
        Text {
            id: statusText

            anchors.top: controls.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.topMargin: 8
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            height: 38

            text: {
                let result = root.downloadStatus

                if (root.downloadOutput.trim().length > 0) {
                    let lines = root.downloadOutput.trim().split("\n")
                    result += " | " + lines.slice(-2).join(" | ")
                }

                return result
            }

            color: Theme.fg
            font.pixelSize: 11

            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Сетка обоев
        FolderListModel {
            id: folder

            folder: "file://" + UiState.home + "/Pictures/Wallpapers"

            nameFilters: [
                "*.jpg",
                "*.jpeg",
                "*.png",
                "*.webp"
            ]

            caseSensitive: false
            showDirs: false

            sortField: FolderListModel.Time
            sortReversed: false
        }

        GridView {
            anchors.top: statusText.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 12

            cellWidth: 195
            cellHeight: 125

            clip: true

            model: folder

            delegate: Item {
                required property string filePath
                required property url fileUrl

                width: 185
                height: 115

                Image {
                    anchors.fill: parent

                    source: fileUrl
                    sourceSize.width: 370

                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        UiState.setWallpaper(filePath)
                        UiState.panel = ""
                    }
                }
            }
        }
    }
}