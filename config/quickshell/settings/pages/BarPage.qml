import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

    readonly property var labels: ({
        launcher: "Launcher",
        workspaces: "Workspaces",
        sysinfo: "CPU / RAM",
        clock: "Clock",
        services: "VPN shield",
        shortcuts: "Shortcuts",
        wallpapers: "Wallpapers",
        themes: "Themes",
        kblayout: "Keyboard layout",
        settings: "Settings",
        power: "Power"
    })

    function sideList(side) {
        return Settings.get("bar.modules." + side, [])
    }

    function move(side, index, delta) {
        const list = JSON.parse(JSON.stringify(page.sideList(side)))
        const j = index + delta
        if (j < 0 || j >= list.length)
            return
        const tmp = list[index]
        list[index] = list[j]
        list[j] = tmp
        Settings.set("bar.modules." + side, list)
    }

    function toggleAt(side, index) {
        const list = JSON.parse(JSON.stringify(page.sideList(side)))
        if (!list[index])
            return
        list[index].enabled = !list[index].enabled
        Settings.set("bar.modules." + side, list)
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            x: 18
            y: 18
            width: parent.width - 36
            spacing: 2

            Text {
                text: "Bar"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Size, transparency, placement and modules."
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            SliderRow {
                width: parent.width
                label: "Height"
                suffix: " px"
                from: 24
                to: 64
                step: 1
                value: Settings.get("bar.height", 36)
                onEdited: (v) => Settings.set("bar.height", Math.round(v))
            }

            SliderRow {
                width: parent.width
                label: "Opacity"
                suffix: ""
                from: 0.3
                to: 1
                step: 0.05
                value: Settings.get("bar.opacity", 0.7)
                onEdited: (v) => Settings.set("bar.opacity", Math.round(v * 100) / 100)
            }

            SelectRow {
                width: parent.width
                label: "Position"
                options: ["top", "bottom"]
                value: Settings.get("bar.position", "top")
                onSelected: (v) => Settings.set("bar.position", v)
            }

            ToggleRow {
                width: parent.width
                label: "Hide in fullscreen"
                checked: Settings.get("bar.hideFullscreen", false)
                onToggled: (v) => Settings.set("bar.hideFullscreen", v)
            }

            Item { width: 1; height: 14 }

            Text {
                text: "Modules"
                color: Theme.accent
                font.pixelSize: 15
                font.bold: true
                bottomPadding: 4
            }

            Text {
                width: parent.width
                text: "Left group, centre and right group. Arrows change order, switch turns a module on or off."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 4
            }

            Repeater {
                model: ["left", "center", "right"]

                Column {
                    id: sideCol
                    required property string modelData
                    readonly property string side: modelData
                    width: col.width
                    spacing: 0

                    Item { width: 1; height: 8 }

                    Text {
                        text: sideCol.side.toUpperCase()
                        color: Theme.muted
                        font.pixelSize: 10
                        font.bold: true
                        bottomPadding: 2
                    }

                    Repeater {
                        model: page.sideList(sideCol.side)

                        BarModuleRow {
                            required property var modelData
                            required property int index

                            width: sideCol.width
                            label: page.labels[modelData.id] || modelData.id
                            enabled: modelData.enabled
                            isFirst: index === 0
                            isLast: index === page.sideList(sideCol.side).length - 1
                            onMoveUp: page.move(sideCol.side, index, -1)
                            onMoveDown: page.move(sideCol.side, index, 1)
                            onToggled: page.toggleAt(sideCol.side, index)
                        }
                    }
                }
            }
        }
    }
}