import QtQuick
import Quickshell

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
            spacing: 6

            Text {
                text: "Themes"
                color: Theme.accent
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Apply a palette to kitty, yazi, micro, Hyprland and hyprlogin."
                color: Theme.muted
                font.pixelSize: 11
                wrapMode: Text.Wrap
                bottomPadding: 6
            }

            Text {
                width: parent.width
                text: ThemeStore.status
                color: Theme.muted
                font.pixelSize: 11
                bottomPadding: 4
            }

            Repeater {
                model: ThemeStore.themes

                Rectangle {
                    id: card
                    required property var modelData

                    readonly property string base: ThemeStore.base(modelData)

                    width: col.width
                    height: 64
                    radius: 10
                    color: Qt.alpha(Theme.surface, 0.45)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        text: card.modelData.name
                        color: Theme.fg
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Row {
                        anchors.right: applyBtn.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Repeater {
                            model: card.modelData.ansi ? [1, 2, 3, 4, 5, 6] : []

                            Rectangle {
                                required property int modelData
                                width: 18
                                height: 14
                                radius: 3
                                color: card.modelData.ansi[modelData]
                                border.color: Theme.bg
                                border.width: 1
                            }
                        }
                    }

                    Rectangle {
                        id: applyBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        height: 30
                        radius: 8
                        color: applyMouse.containsMouse ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: Theme.bg
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: applyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ThemeStore.apply(card.base)
                        }
                    }
                }
            }
        }
    }
}