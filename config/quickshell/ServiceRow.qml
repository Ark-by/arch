import QtQuick

// Строка сервиса: название, статус и переключатель
Item {
    id: root
    property string title: ""
    property bool checked: false
    property bool busy: false
    signal toggled()

    height: 56

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rowMa.containsMouse ? Theme.surface : "transparent"
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text { text: root.title; color: Theme.fg; font.pixelSize: 15 }
        Text {
            text: root.busy ? "Подождите…" : (root.checked ? "Включено" : "Выключено")
            color: (root.checked && !root.busy) ? Theme.accent : Theme.muted
            font.pixelSize: 12
        }
    }

    Rectangle {                      // сам переключатель
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 46; height: 24; radius: 12
        color: root.checked ? Theme.accent : Theme.surface
        border.color: Theme.muted
        border.width: root.checked ? 0 : 1
        opacity: root.busy ? 0.5 : 1

        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.bg : Theme.fg
            Behavior on x { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.busy
        onClicked: root.toggled()
    }
}
