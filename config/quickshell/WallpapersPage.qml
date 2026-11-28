import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: page

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: home + "/Pictures/Wallpapers"

    property string pageNumber: "14"
    property string status: ""
    property string pendingDelete: ""
    property bool showSources: false
    property bool showHelp: false

    function refresh() {
        const f = folder.folder
        folder.folder = ""
        folder.folder = f
    }

    function applyWallpaper(path) {
        UiState.setWallpaper(path)
        SettingsStore.set("wallpaperPath", path)
        page.status = "Applied: " + path.substring(path.lastIndexOf("/") + 1)
    }

    function askDelete(path, permanent) {
        if (permanent === true) {
            remover.target = path
            remover.running = true
            page.pendingDelete = ""
            return
        }
        if (page.pendingDelete === path) {
            trash.target = path
            trash.running = true
            page.pendingDelete = ""
        } else {
            page.pendingDelete = path
            page.status = "Press × again to move to trash (Shift+× deletes permanently)"
            confirmTimer.restart()
        }
    }

    function savedSources() {
        const list = SettingsStore.get("savedSources", [])
        return Array.isArray(list) ? list : []
    }

    function saveSource() {
        const url = ("" + SettingsStore.get("sourceUrl", "")).trim()
        if (url === "") {
            page.status = "Source URL is empty"
            return
        }
        const list = JSON.parse(JSON.stringify(page.savedSources()))
        if (list.indexOf(url) < 0)
            list.push(url)
        SettingsStore.set("savedSources", list)
        SettingsStore.set("sourceUrl", url)
        SettingsStore.apply()
        page.status = "Saved to list"
        page.showSources = false
    }

    function useSource(url) {
        SettingsStore.set("sourceUrl", url)
        page.status = "Selected source"
        page.showSources = false
    }

    function removeSource(url) {
        const list = JSON.parse(JSON.stringify(page.savedSources()))
        const i = list.indexOf(url)
        if (i >= 0)
            list.splice(i, 1)
        SettingsStore.set("savedSources", list)
        page.status = "Removed from list"
    }

    function download() {
        if (downloadProc.running)
            return
        page.status = "Downloading page " + page.pageNumber + "…"
        const src = ("" + SettingsStore.get("sourceUrl", "")).trim()
        const key = ("" + SettingsStore.get("apiKey", "")).trim()
        const cmd = ["bash", page.home + "/.local/bin/wallhaven-download.sh", page.pageNumber, src]
        if (key !== "")
            cmd.push(key)
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

    Process {
        id: remover
        property string target: ""
        command: ["rm", "-f", remover.target]
        onExited: (code, status) => {
            page.status = code === 0 ? "Deleted permanently" : "Delete failed (" + code + ")"
            page.refresh()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Wallpapers"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: helpMouse.containsMouse ? Theme.surface : "transparent"
                border.color: Theme.accent
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "?"
                    color: Theme.accent
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: helpMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.showHelp = !page.showHelp
                }
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            text: "~/Pictures/Wallpapers · click to apply · × moves to trash · Shift+× deletes permanently"
            color: Theme.muted
            font.pixelSize: 11
        }

        // ---------- API key ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "API key"
                color: Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: apiKeyInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: apiKeyInput
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: SettingsStore.get("apiKey", "")
                    selectByMouse: true
                    clip: true
                    echoMode: TextInput.Normal
                    onTextEdited: SettingsStore.set("apiKey", text)
                    onEditingFinished: SettingsStore.set("apiKey", text)
                }
            }

            Rectangle {
                width: 66
                height: 30
                radius: 7
                color: apiSaveMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: apiSaveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SettingsStore.set("apiKey", apiKeyInput.text.trim())
                        SettingsStore.apply()
                        page.status = "API key saved"
                    }
                }
            }
        }

        // ---------- источник ----------
        RowLayout {
            id: sourceRow
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
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    text: SettingsStore.get("sourceUrl", "")
                    selectByMouse: true
                    clip: true
                    onTextEdited: SettingsStore.set("sourceUrl", text)
                    onEditingFinished: SettingsStore.set("sourceUrl", text)
                }
            }

            Rectangle {
                width: 30
                height: 30
                radius: 7
                color: page.showSources ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.surface, 0.7)
                border.color: page.showSources ? Theme.accent : Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "▾"
                    color: Theme.accent
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.showSources = !page.showSources
                }
            }

            Rectangle {
                width: 66
                height: 30
                radius: 7
                color: saveMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.saveSource()
                }
            }
        }

        // ---------- страница Wallhaven ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Page"
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
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // ---------- сетка ----------
        GridView {
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
                        onClicked: (m) => page.askDelete(filePath, (m.modifiers & Qt.ShiftModifier) !== 0)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: folder.count === 0
            text: "No wallpapers yet — download a page above, or drop files into ~/Pictures/Wallpapers."
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }

    // ---------- список сохранённых источников ----------
    MouseArea {
        anchors.fill: parent
        visible: page.showSources
        onClicked: page.showSources = false
    }

    Rectangle {
        id: sourcesPopup
        visible: page.showSources

        readonly property point anchor: sourceRow.mapToItem(page, 0, 0)

        x: page.width - 18 - width
        y: anchor.y + sourceRow.height + 4
        width: 420
        height: Math.min(190, sourcesList.contentHeight + 12)

        radius: 10
        color: Qt.alpha(Theme.bg, 0.98)
        border.color: Theme.accent
        border.width: 1
        clip: true

        ListView {
            id: sourcesList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            spacing: 2
            model: page.savedSources()

            delegate: Rectangle {
                required property string modelData

                readonly property bool current: modelData === SettingsStore.get("sourceUrl", "")

                width: sourcesList.width
                height: 32
                radius: 6
                color: current ? Qt.alpha(Theme.accent, 0.22) : (rowMouse.containsMouse ? Theme.surface : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: removeBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: current ? Theme.fg : Theme.muted
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideMiddle
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.useSource(modelData)
                }

                Rectangle {
                    id: removeBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 5
                    color: removeMouse.containsMouse ? Qt.alpha(Theme.error, 0.25) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.error
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.removeSource(modelData)
                    }
                }
            }
        }
    }
    // ---------- справка ----------
    MouseArea {
        anchors.fill: parent
        visible: page.showHelp
        onClicked: page.showHelp = false
    }

    Rectangle {
        id: helpPanel
        visible: page.showHelp
        anchors.centerIn: parent
        width: Math.min(620, page.width - 80)
        height: helpColumn.implicitHeight + 40
        radius: 12
        color: Qt.alpha(Theme.bg, 0.98)
        border.color: Theme.accent
        border.width: 1

        Column {
            id: helpColumn
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Text {
                text: "Wallpapers — help"
                color: Theme.accent
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                width: parent.width
                color: Theme.fg
                font.pixelSize: 12
                wrapMode: Text.Wrap
                lineHeight: 1.25
                text: "Click a wallpaper to apply it. The choice is saved to ~/.config/quickshell/wallpaper.txt.\n\n"
                    + "× moves the file to the trash (recoverable). Shift+× deletes it permanently.\n\n"
                    + "Source URL accepts any Wallhaven page: /hot, /toplist, /random, /latest, /search?q=..., /collections/<user>/<id>. "
                    + "Site links are converted to API links automatically, so you can paste what you see in the browser.\n\n"
                    + "Save stores the current URL in the saved list; the ▾ button opens that list (click to use, × to remove).\n\n"
                    + "API key is optional. Create one at wallhaven.cc/settings/account. It is required for NSFW results and some collections; "
                    + "the key is appended to every request as &apikey=...\n\n"
                    + "Page is the page number to download. Files go to ~/Pictures/Wallpapers."
            }

            Rectangle {
                width: 100
                height: 30
                radius: 8
                color: helpCloseMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: Theme.bg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: helpCloseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.showHelp = false
                }
            }
        }
    }
}