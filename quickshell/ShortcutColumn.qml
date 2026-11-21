import QtQuick

// Колонка разделов: заголовок + строки «плашки клавиш — описание»
Column {
    id: root
    property var sections: []
    spacing: 14

    Repeater {
        model: root.sections
        delegate: Column {
            required property var modelData
            width: root.width
            spacing: 4

            Text {
                text: modelData.title
                color: Theme.accent
                font.pixelSize: 15
                font.bold: true
                bottomPadding: 4
            }

            Repeater {
                model: modelData.items
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 28

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: modelData.keys.split(" + ")
                            delegate: Rectangle {
                                required property string modelData
                                height: 22
                                width: keyText.implicitWidth + 14
                                radius: 5
                                color: Theme.surface
                                border.color: Theme.muted
                                border.width: 1
                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Theme.fg
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        color: Theme.fg
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
