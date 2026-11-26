import QtQuick

// Кнопка-иконка: подсвечивается при наведении
Text {
    id: root
    signal clicked()
    property color baseColor: Theme.fg
    property color hoverColor: Theme.accent

    font.family: Settings.get("fonts.ui_family", "JetBrainsMono Nerd Font")
    font.pixelSize: Settings.get("fonts.ui_size", 14) + 4
    color: ma.containsMouse ? hoverColor : baseColor

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
