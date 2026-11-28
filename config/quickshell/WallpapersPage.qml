import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: page

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: home + "/Pictures/Wallpapers"
    readonly property string cfgPath: home + "/.local/state/quickshell/settings.json"

    property string sourceUrl: "https://wallhaven.cc/api/v1/collections/lewdpatriot/935888"
    property string apiKey: ""
    property string pageNumber: "14"
    property string status: ""

    function refresh() {
        const f = folder.folder
        folder.folder = ""
        folder.folder = f
    }

    function applyWallpaper(path) {
        UiState.setWallpaper(path)
        page.status = "Applied: " + path.substring(path.lastIndexOf("/") + 1)
    }

    function saveCfg() {
        const obj = { sourceUrl: page.sourceUrl, apiKey: page.apiKey }
        saver.payload = JSON.stringify(obj, null, 2) + "\n"
        saver.running = true
    }

    function download() {
        if (downloadProc.running)
            return
        page.status = "Downloading page " + page.pageNumber + "…"
        const cmd = ["bash", page.home + "/.local/bin/wallhaven-download.sh", page.pageNumber, page.sourceUrl]
        if (page.apiKey !== "")
            cmd.push(page.apiKey)
        downloadProc.command = cmd
        downloadProc.running = true
    }

    FolderListModel {
        id: folder
        folder: "file://" + page.wallDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Time
        sortReversed: true
    }

    Process {
        id: cfgReader
        command: ["cat", page.cfgPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = ("" + this.text).trim()
                if (raw === "")
                    return
                try {
                    const o = JSON.parse(raw)
                    if (o.sourceUrl) page.sourceUrl = o.sourceUrl
                    if (o.apiKey !== undefined) page.apiKey = o.apiKey
                } catch (e) {
                    page.status = "settings.json: " + e
                }
            }
        }
    }

    Process {
        id: saver
        property string payload: ""
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"", "ark", saver.payload, page.cfgPath]
        onExited: (code, status) => page.status = code === 0 ? "Saved" : "Save failed (" + code + ")"
    }

    Process {
        id: downloadProc
        stdout: StdioCollector {
            onStreamFinished: page.status = "Output: " + this.text.trim().slice(-100)
        }
        onExited: (code, status) => {
            if (code !== 0)
                page.status = "Download failed (" + code + ")"
            page.refresh()
        }
    }

    Component.onCompleted: cfgReader.running = true

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        Text {
            text: "Wallpapers"
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: "~/Pictures/Wallpapers · click to apply"
            color: Theme.muted
            font.pixelSize: 11
        }

        Text {
            text: "Source URL"
            color: Theme.fg
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: 28
            radius: 7
            color: Qt.alpha(Theme.surface, 0.7)
            border.color: sourceInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            TextInput {
                id: sourceInput
                anchors.fill: parent
                anchors.margins: 7
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                text: page.sourceUrl
                selectByMouse: true
                clip: true
                onTextEdited: page.sourceUrl = text
            }
        }

        Text {
            text: "API key (optional)"
            color: Theme.fg
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: 28
            radius: 7
            color: Qt.alpha(Theme.surface, 0.7)
            border.color: keyInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            TextInput {
                id: keyInput
                anchors.fill: parent
                anchors.margins: 7
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                text: page.apiKey
                selectByMouse: true
                clip: true
                onTextEdited: page.apiKey = text
            }
        }

        Row {
            spacing: 8

            Rectangle {
                width: 80
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: Theme.border
                border.width: 1

                TextInput {
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.fg
                    font.pixelSize: 12
                    text: page.pageNumber
                    validator: IntValidator { bottom: 1; top: 100000 }
                    onTextChanged: page.pageNumber = text
                }
            }

            Rectangle {
                width: 90
                height: 28
                radius: 7
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Download"
                    color: Theme.bg
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.download()
                }
            }

            Rectangle {
                width: 70
                height: 28
                radius: 7
                color: "transparent"
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: Theme.fg
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.saveCfg()
                }
            }
        }

        Text {
            width: parent.width
            text: page.status
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        GridView {
            width: parent.width
            height: parent.height - 260
            clip: true
            cellWidth: 196
            cellHeight: 128
            model: folder

            delegate: Item {
                required property string filePath
                required property url fileUrl

                width: 186
                height: 118

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Qt.alpha(Theme.surface, 0.5)
                    border.color: Theme.border
                    border.width: 1
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: fileUrl
                    sourceSize.width: 372
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    clip: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.applyWallpaper(filePath)
                }
            }
        }
    }
}