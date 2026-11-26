import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs

Item {
    id: page

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: home + "/Pictures/Wallpapers"

    property string pageNumber: "14"
    property string status: ""
    property string pendingDelete: ""

    function refresh() {
        const f = folder.folder
        folder.folder = ""
        folder.folder = f
    }

    function applyWallpaper(path) {
        UiState.setWallpaper(path)
        Settings.set("wallpaper.path", path)
        page.status = "Applied: " + path.substring(path.lastIndexOf("/") + 1)
    }

    function askDelete(path) {
        if (page.pendingDelete === path) {
            trash.target = path
            trash.running = true
            page.pendingDelete = ""
        } else {
            page.pendingDelete = path
            page.status = "Press × again to move to trash"
            confirmTimer.restart()
        }
    }

    function download() {
        if (downloadProc.running)
            return
        page.status = "Downloading page " + page.pageNumber + "…"
        downloadOut.text = ""
        const src = ("" + Settings.get("wallpaper.sourceUrl", "")).trim()
        const cmd = ["bash", page.home + "/.local/bin/wallhaven-download.sh", page.pageNumber]
        if (src !== "")
            cmd.push(src)
        downloadProc.command = cmd
        downloadProc.running = true
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: page.pendingDelete = ""
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
        id: downloadProc
        stdout: StdioCollector {
            id: downloadOut
            onStreamFinished: page.status = "Output: " + this.text.trim().slice(-120)
        }
        onExited: (code, status) => {
            if (code !== 0)
                page.status = "Download failed (" + code + ")"
            page.refresh()
        }
    }

    Process {
        id: trash
        property string target: ""
        command: ["gio", "trash", trash.target]
        onExited: (code, status) => {
            page.status = code === 0 ? "Moved to trash" : "Trash failed (" + code + ")"
            page.refresh()
        }
    }

    ColumnLayout {
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
            Layout.fillWidth: true
            text: "~/Pictures/Wallpapers · click to apply · × moves to trash"
            color: Theme.muted
            font.pixelSize: 11
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Source URL"
                color: Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: sourceInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: sourceInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: Settings.get("wallpaper.sourceUrl", "")
                    selectByMouse: true
                    clip: true
                    onTextEdited: Settings.set("wallpaper.sourceUrl", text)
                    onEditingFinished: Settings.set("wallpaper.sourceUrl", text)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Wallhaven page"
                color: Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                width: 80
                height: 30
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
                    onAccepted: page.download()
                }
            }

            Rectangle {
                width: 110
                height: 30
                radius: 7
                color: downloadProc.running ? Theme.muted : (dlMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent)

                Text {
                    anchors.centerIn: parent
                    text: downloadProc.running ? "Downloading…" : "Download"
                    color: Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: dlMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !downloadProc.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.download()
                }
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            visible: page.status !== ""
            text: page.status
            color: Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    border.color: page.pendingDelete === filePath ? Theme.error : Theme.border
                    border.width: page.pendingDelete === filePath ? 2 : 1
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

                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 22
                    height: 22
                    radius: 6
                    color: page.pendingDelete === filePath ? Theme.error : Qt.alpha(Theme.bg, 0.8)
                    border.color: page.pendingDelete === filePath ? Theme.error : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: page.pendingDelete === filePath ? Theme.bg : Theme.fg
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.askDelete(filePath)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: folder.count === 0
            text: "No wallpapers yet — download a Wallhaven page above, or drop files into ~/Pictures/Wallpapers."
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}