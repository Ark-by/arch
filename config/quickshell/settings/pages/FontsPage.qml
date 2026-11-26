import QtQuick
import Quickshell
import qs
import qs.settings

Item {
    id: page

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
            spacing: 4

            Text {
                text: "Fonts"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Panel and terminal fonts apply live. kitty is reloaded, Zed needs a restart."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            // ---------- панель ----------
            Text {
                text: "Panel"
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 2
            }

            SliderRow {
                width: parent.width
                label: "UI size"
                suffix: " px"
                from: 10
                to: 20
                step: 1
                value: Settings.get("fonts.ui_size", 14)
                onEdited: (v) => Settings.set("fonts.ui_size", Math.round(v))
            }

            Item { width: 1; height: 12 }

            // ---------- kitty ----------
            Text {
                text: "kitty"
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 2
            }

            Text {
                text: "Family"
                color: Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                width: parent.width
                height: 28
                radius: 7
                color: Qt.alpha(Theme.surface, 0.7)
                border.color: kittyFamily.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: kittyFamily
                    anchors.fill: parent
                    anchors.margins: 7
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 12
                    text: Settings.get("fonts.kitty_family", "JetBrainsMono Nerd Font Mono")
                    selectByMouse: true
                    clip: true
                    onTextEdited: Settings.set("fonts.kitty_family", text)
                    onEditingFinished: Settings.set("fonts.kitty_family", text)
                }
            }

            SliderRow {
                width: parent.width
                label: "kitty size"
                suffix: " pt"
                from: 8
                to: 20
                step: 0.5
                value: Settings.get("fonts.kitty_size", 10.5)
                onEdited: (v) => Settings.set("fonts.kitty_size", v)
            }

            Rectangle {
                width: 150
                height: 30
                radius: 8
                color: panelApply.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Apply kitty font"
                    color: Theme.bg
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: panelApply
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: FontStore.applyKitty(
                        Settings.get("fonts.kitty_family", "JetBrainsMono Nerd Font Mono"),
                        Settings.get("fonts.kitty_size", 10.5))
                }
            }

            Item { width: 1; height: 12 }

            // ---------- Zed ----------
            Text {
                text: "Zed"
                color: Theme.accent
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 2
            }

            SliderRow {
                width: parent.width
                label: "Buffer size"
                suffix: " px"
                from: 8
                to: 24
                step: 0.5
                value: Settings.get("fonts.zed_buffer_size", 14)
                onEdited: (v) => Settings.set("fonts.zed_buffer_size", v)
            }

            SliderRow {
                width: parent.width
                label: "UI size"
                suffix: " px"
                from: 8
                to: 24
                step: 0.5
                value: Settings.get("fonts.zed_ui_size", 14)
                onEdited: (v) => Settings.set("fonts.zed_ui_size", v)
            }

            SliderRow {
                width: parent.width
                label: "Terminal size"
                suffix: " px"
                from: 8
                to: 24
                step: 0.5
                value: Settings.get("fonts.zed_terminal_size", 14)
                onEdited: (v) => Settings.set("fonts.zed_terminal_size", v)
            }

            Item { width: 1; height: 6 }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: 150
                    height: 30
                    radius: 8
                    color: zedApply.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Apply Zed fonts"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: zedApply
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: FontStore.applyZed(
                            Settings.get("fonts.zed_buffer_family", "JetBrainsMono Nerd Font"),
                            Settings.get("fonts.zed_buffer_size", 14),
                            Settings.get("fonts.zed_ui_family", "JetBrainsMono Nerd Font"),
                            Settings.get("fonts.zed_ui_size", 14),
                            Settings.get("fonts.zed_terminal_family", "JetBrainsMono Nerd Font"),
                            Settings.get("fonts.zed_terminal_size", 14))
                    }
                }

                Rectangle {
                    width: 150
                    height: 30
                    radius: 8
                    color: allApply.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Apply everything"
                        color: Theme.bg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: allApply
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            FontStore.applyKitty(
                                Settings.get("fonts.kitty_family", "JetBrainsMono Nerd Font Mono"),
                                Settings.get("fonts.kitty_size", 10.5))
                            FontStore.applyZed(
                                Settings.get("fonts.zed_buffer_family", "JetBrainsMono Nerd Font"),
                                Settings.get("fonts.zed_buffer_size", 14),
                                Settings.get("fonts.zed_ui_family", "JetBrainsMono Nerd Font"),
                                Settings.get("fonts.zed_ui_size", 14),
                                Settings.get("fonts.zed_terminal_family", "JetBrainsMono Nerd Font"),
                                Settings.get("fonts.zed_terminal_size", 14))
                            Settings.apply()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: FontStore.status
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }
}