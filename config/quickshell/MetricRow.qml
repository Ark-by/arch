import QtQuick

// Одна метрика: название, значение, полоска загрузки и (по желанию) график за минуту
Item {
    id: root
    property string title: ""
    property string valueText: ""
    property real percent: 0
    property bool showGraph: false
    property var history: []
    readonly property color levelColor: percent > 85 ? "#f38ba8" : (percent > 60 ? "#f9e2af" : Theme.accent)

    height: showGraph ? 84 : 42

    Text { text: root.title; color: Theme.fg; font.pixelSize: 14 }
    Text { anchors.right: parent.right; text: root.valueText; color: Theme.muted; font.pixelSize: 13 }

    Rectangle {
        y: 22
        width: parent.width; height: 8; radius: 4
        color: Theme.surface
        Rectangle {
            width: parent.width * Math.min(1, Math.max(0, root.percent / 100))
            height: parent.height; radius: 4
            color: root.levelColor
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }

    Item {
        id: graph
        visible: root.showGraph
        y: 38
        width: parent.width; height: 40
        Row {
            anchors.fill: parent
            spacing: 1
            Repeater {
                model: 60
                Item {
                    required property int index
                    width: (graph.width - 59) / 60
                    height: graph.height
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(1, parent.height * ((root.history[index - (60 - root.history.length)] || 0) / 100))
                        color: root.levelColor
                        opacity: 0.75
                    }
                }
            }
        }
    }
}
