import QtQuick
import Quickshell
import Quickshell.Hyprland

// Один модуль бара: kind выбирает, что рисовать.
Item {
    id: root

    property string kind: ""

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 24

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.pick()
    }

    function pick() {
        switch (root.kind) {
        case "launcher":   return launcherComp
        case "workspaces": return workspacesComp
        case "sysinfo":    return sysinfoComp
        case "clock":      return clockComp
        case "services":   return servicesComp
        case "shortcuts":  return shortcutsComp
        case "wallpapers": return wallpapersComp
        case "themes":     return themesComp
        case "kblayout":   return kblayoutComp
        case "settings":   return settingsComp
        case "power":      return powerComp
        }
        return null
    }

    Component {
        id: launcherComp
        IconButton {
            text: "\uf303"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("launcher")
        }
    }

    Component {
        id: workspacesComp
        Row {
            spacing: 6
            Repeater {
                model: Hyprland.workspaces.values
                Rectangle {
                    required property var modelData
                    width: 26
                    height: 22
                    radius: 6
                    color: modelData.focused ? Theme.accent : Theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        color: modelData.focused ? Theme.bg : Theme.accent
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }

    Component {
        id: sysinfoComp
        Text {
            text: "CPU " + ("" + Math.round(SysInfo.cpu)).padStart(3, "") + "% RAM " + ("" + Math.round(SysInfo.memPct)).padStart(3, "") + "%"
            color: Theme.accent
            font.pixelSize: 13
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: UiState.toggle("monitor")
            }
        }
    }

    Component {
        id: clockComp
        Item {
            implicitWidth: clockText.implicitWidth
            implicitHeight: clockText.implicitHeight

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Text {
                id: clockText
                text: Qt.locale("ru_RU").toString(clock.date, "dddd d MMMM  HH:mm")
                    .replace(/(^|\s)(\S)/g, (m, a, b) => a + b.toUpperCase())
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
            }
        }
    }

    Component {
        id: servicesComp
        IconButton {
            text: "\uf132"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("services")
        }
    }

    Component {
        id: shortcutsComp
        IconButton {
            text: "\uf11c"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("shortcuts")
        }
    }

    Component {
        id: wallpapersComp
        IconButton {
            text: "\uf03e"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("wallpaper")
        }
    }

    Component {
        id: themesComp
        IconButton {
            text: "\uf1fc"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("themes")
        }
    }

    Component {
        id: kblayoutComp
        IconButton {
            text: KbLayout.code
            font.pixelSize: 15
            font.bold: true
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        }
    }

    Component {
        id: settingsComp
        IconButton {
            text: "\uf013"
            baseColor: Theme.accent
            hoverColor: Theme.fg
            onClicked: UiState.toggle("settings")
        }
    }

    Component {
        id: powerComp
        IconButton {
            text: "\uf011"
            hoverColor: Theme.error
            onClicked: UiState.toggle("power")
        }
    }
}