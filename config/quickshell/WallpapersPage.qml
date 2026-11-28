import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Обои: «В сети» (миниатюры Wallhaven, ничего не качаем) и «На диске» (~/Pictures/Wallpapers).
// Клик по сетевой плитке — полноэкранное превью (WallpaperPreview.qml).
// ⤓ на плитке — скачать сразу в ~/Pictures/Wallpapers и применить.
Item {
    id: page

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: home + "/Pictures/Wallpapers"

    property string mode: "net"          // "net" | "disk"
    property string pageNumber: "1"
    property int currentPage: 1
    property int lastPage: 1
    property var netItems: []
    property bool listing: false
    property string status: ""
    property string downloadingId: ""
    property string dlExt: "jpg"
    property var savedIds: ({})
    property string pendingDelete: ""
    property bool showSources: false

    // ---------- сеть ----------
    function sourceUrl() {
        return ("" + SettingsStore.get("sourceUrl", "")).trim()
    }

    function loadPage() {
        if (listing)
            return
        const n = parseInt(page.pageNumber, 10)
        if (!(n > 0)) {
            page.status = "Номер страницы должен быть числом"
            return
        }
        page.listing = true
        page.status = "Загружаю страницу " + n + "…"
        const cmd = ["bash", page.home + "/.local/bin/wallhaven-list.sh", "" + n, page.sourceUrl()]
        const key = ("" + SettingsStore.get("apiKey", "")).trim()
        if (key !== "")
            cmd.push(key)
        lister.command = cmd
        lister.running = true
    }

    function handleListing(text) {
        const items = []
        let meta = null
        const lines = ("" + text).split("\n")
        for (let i = 0; i < lines.length; i++) {
            const s = lines[i].trim()
            if (s === "")
                continue
            try {
                const o = JSON.parse(s)
                if (o && o.meta)
                    meta = o.meta
                else if (o && o.id)
                    items.push(o)
            } catch (e) {
                console.log("wallhaven-list: " + e)
            }
        }
        page.netItems = items
        if (meta) {
            page.currentPage = meta.page
            page.lastPage = meta.lastPage
            page.pageNumber = "" + meta.page
        }
        if (items.length === 0) {
            page.status = "Ничего не найдено — проверь URL (NSFW скрыто без API-ключа)"
        } else {
            page.status = items.length + " обоев · страница " + page.currentPage + " из " + page.lastPage
        }
    }

    function goPage(delta) {
        const n = page.currentPage + delta
        if (n < 1 || n > page.lastPage)
            return
        page.pageNumber = "" + n
        page.loadPage()
    }

    function download(item) {
        if (page.downloadingId !== "")
            return
        const ext = ("" + item.path).substring(("" + item.path).lastIndexOf(".") + 1).toLowerCase()
        page.dlExt = ext
        page.downloadingId = item.id
        page.status = "Скачиваю " + item.id + "…"
        dlProc.command = ["bash", "-c",
            "mkdir -p \"$1\" && curl -fsSL --max-time 90 --retry 2 -o \"$2\" \"$3\"",
            "sh", page.wallDir, page.wallDir + "/" + item.id + "." + ext, item.path]
        dlProc.running = true
    }

    function refreshSaved() {
        const m = ({})
        for (let i = 0; i < folder.count; i++) {
            const name = "" + folder.get(i, "fileName")
            const dot = name.lastIndexOf(".")
            if (dot > 0)
                m[name.substring(0, dot)] = true
        }
        page.savedIds = m
    }

    // ---------- диск ----------
    function refresh() {
        const f = folder.folder
        folder.folder = ""
        folder.folder = f
        page.refreshSaved()
    }

    function applyWallpaper(path) {
        UiState.setWallpaper(path)
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
            page.status = "Нажми × ещё раз — в корзину (Shift+× — удалить навсегда)"
            confirmTimer.restart()
        }
    }

    // ---------- сохранённые источники ----------
    function savedSources() {
        const list = SettingsStore.get("savedSources", [])
        return Array.isArray(list) ? list : []
    }

    function saveSource() {
        const url = page.sourceUrl()
        if (url === "") {
            page.status = "URL пустой"
            return
        }
        const list = JSON.parse(JSON.stringify(page.savedSources()))
        if (list.indexOf(url) < 0)
            list.push(url)
        SettingsStore.set("savedSources", list)
        SettingsStore.set("sourceUrl", url)
        SettingsStore.apply()
        page.status = "Источник сохранён"
        page.showSources = false
    }

    function useSource(url) {
        SettingsStore.set("sourceUrl", url)
        page.showSources = false
        page.status = "Источник выбран"
    }

    function removeSource(url) {
        const list = JSON.parse(JSON.stringify(page.savedSources()))
        const i = list.indexOf(url)
        if (i >= 0)
            list.splice(i, 1)
        SettingsStore.set("savedSources", list)
        page.status = "Убрано из списка"
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
        onCountChanged: page.refreshSaved()
    }

    // ---------- процессы ----------
    Process {
        id: lister
        property var cmd: []
        command: cmd
        stdout: StdioCollector {
            onStreamFinished: page.handleListing(this.text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const t = ("" + this.text).trim()
                if (t !== "")
                    page.status = t
            }
        }
        onExited: (code) => {
            page.listing = false
            if (code !== 0 && page.status === "")
                page.status = "Не удалось загрузить (" + code + ")"
        }
    }

    Process {
        id: dlProc
        property var cmd: []
        command: cmd
        onExited: (code) => {
            const id = page.downloadingId
            page.downloadingId = ""
            if (code === 0) {
                const m = ({})
                const cur = page.savedIds
                for (const k in cur)
                    m[k] = cur[k]
                m[id] = true
                page.savedIds = m
                page.status = "Скачано и применено: " + id
                UiState.setWallpaper(page.wallDir + "/" + id + "." + page.dlExt)
                page.refresh()
            } else {
                page.status = "Ошибка загрузки (" + code + ")"
            }
        }
    }

    Process {
        id: trash
        property string target: ""
        command: ["gio", "trash", trash.target]
        onExited: (code, status) => {
            page.status = code === 0 ? "В корзине" : "Не удалось в корзину (" + code + ")"
            page.refresh()
        }
    }

    Process {
        id: remover
        property string target: ""
        command: ["rm", "-f", remover.target]
        onExited: (code, status) => {
            page.status = code === 0 ? "Удалено навсегда" : "Не удалось удалить (" + code + ")"
            page.refresh()
        }
    }

    Component.onCompleted: page.refreshSaved()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        // ---------- заголовок и переключатель ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Wallpapers"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 92
                height: 28
                radius: 7
                color: page.mode === "net" ? Theme.accent : "transparent"
                border.color: page.mode === "net" ? Theme.accent : Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "В сети"
                    color: page.mode === "net" ? Theme.bg : Theme.fg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.mode = "net"
                }
            }

            Rectangle {
                width: 100
                height: 28
                radius: 7
                color: page.mode === "disk" ? Theme.accent : "transparent"
                border.color: page.mode === "disk" ? Theme.accent : Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "На диске"
                    color: page.mode === "disk" ? Theme.bg : Theme.fg
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        page.mode = "disk"
                        page.refresh()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // ================= В СЕТИ =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: page.mode === "net"

            // источник
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Источник"
                    color: Theme.fg
                    font.pixelSize: 12
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.7)
                    border.color: urlInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: urlInput
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        text: SettingsStore.get("sourceUrl", "")
                        selectByMouse: true
                        clip: true
                        onTextEdited: SettingsStore.set("sourceUrl", text)
                        Keys.onReturnPressed: page.loadPage()
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: page.showSources ? Qt.alpha(Theme.accent, 0.22) : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "▾"
                        color: Theme.fg
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.showSources = !page.showSources
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "★"
                        color: Theme.accent
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.saveSource()
                    }
                }
            }

            // страница + кнопка + пейджер
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Стр."
                    color: Theme.fg
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 56
                    height: 28
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.7)
                    border.color: pageInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: pageInput
                        anchors.fill: parent
                        anchors.margins: 6
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        color: Theme.fg
                        font.pixelSize: 12
                        text: page.pageNumber
                        validator: IntValidator { bottom: 1; top: 100000 }
                        onTextEdited: page.pageNumber = text
                        Keys.onReturnPressed: page.loadPage()
                    }
                }

                Rectangle {
                    width: 118
                    height: 28
                    radius: 7
                    color: page.listing ? Theme.muted : (loadMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent)

                    Text {
                        anchors.centerIn: parent
                        text: page.listing ? "Загружаю…" : "Загрузить в UI"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: loadMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !page.listing
                        onClicked: page.loadPage()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: "transparent"
                    border.color: page.currentPage <= 1 ? Theme.muted : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        color: page.currentPage <= 1 ? Theme.muted : Theme.fg
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.goPage(-1)
                    }
                }

                Text {
                    text: page.currentPage + " / " + page.lastPage
                    color: Theme.muted
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: "transparent"
                    border.color: page.currentPage >= page.lastPage ? Theme.muted : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: page.currentPage >= page.lastPage ? Theme.muted : Theme.fg
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.goPage(1)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page.status !== ""
                text: page.status
                color: page.status.startsWith("Ошибка") || page.status.startsWith("Не удалось") ? Theme.error : Theme.muted
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // сетка сети
            GridView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 196
                cellHeight: 128
                model: page.netItems

                delegate: Item {
                    required property var modelData

                    width: 186
                    height: 118

                    readonly property bool saved: page.savedIds[modelData.id] === true
                    readonly property bool busy: page.downloadingId === modelData.id

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.alpha(Theme.surface, 0.5)
                        border.color: saved ? Qt.alpha(Theme.success, 0.8) : Theme.border
                        border.width: 1
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: modelData.thumb
                        sourceSize.width: 372
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        clip: true
                    }

                    // разрешение
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        width: resText.implicitWidth + 8
                        height: 16
                        radius: 4
                        color: Qt.alpha(Theme.bg, 0.75)

                        Text {
                            id: resText
                            anchors.centerIn: parent
                            text: modelData.resolution
                            color: Theme.fg
                            font.pixelSize: 9
                        }
                    }

                    // скачать
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 24
                        height: 24
                        radius: 6
                        color: parent.saved
                            ? Qt.alpha(Theme.success, 0.85)
                            : (dlMouse.containsMouse ? Theme.accent : Qt.alpha(Theme.bg, 0.8))
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.saved ? "✓" : (parent.parent.busy ? "…" : "⤓")
                            color: parent.parent.saved ? Theme.bg : Theme.fg
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: dlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !parent.parent.saved && !parent.parent.busy
                            onClicked: page.download(modelData)
                        }
                    }

                    // клик по картинке — превью
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UiState.openPreview(modelData.id, modelData.thumb, modelData.path, modelData.resolution)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page.netItems.length === 0 && !page.listing
                text: "Введи ссылку (например https://wallhaven.cc/toplist), страницу и нажми «Загрузить в UI». Обои не скачиваются — только миниатюры."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }

        // ================= НА ДИСКЕ =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: page.mode === "disk"

            Text {
                Layout.fillWidth: true
                text: "~/Pictures/Wallpapers · клик — применить, × — в корзину"
                color: Theme.muted
                font.pixelSize: 11
            }

            Text {
                Layout.fillWidth: true
                visible: page.status !== ""
                text: page.status
                color: page.status.startsWith("Ошибка") || page.status.startsWith("Не удалось") ? Theme.error : Theme.muted
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
            }

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
                text: "Пока пусто — скачай обои во вкладке «В сети» или положи файлы в ~/Pictures/Wallpapers."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }

    // ---------- попап сохранённых источников ----------
    MouseArea {
        anchors.fill: parent
        visible: page.showSources
        onClicked: page.showSources = false
    }

    Rectangle {
        id: sourcesPopup
        visible: page.showSources
        x: page.width - width - 18
        y: 96
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
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 5
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.muted
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.removeSource(modelData)
                    }
                }
            }
        }
    }
}
