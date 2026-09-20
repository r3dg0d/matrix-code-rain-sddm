// Minimal button: black interior, thin green outline, monospace label.
import QtQuick

Item {
    id: button

    property string label: "OK"
    property real uiScale: 1.0
    property string fontFamily: "monospace"
    property color bright: "#00FF41"
    property color dim: "#008F11"
    property bool compact: false

    activeFocusOnTab: true

    signal clicked()

    implicitHeight: Math.round((compact ? 24 : 34) * uiScale)
    implicitWidth: Math.round(labelText.implicitWidth + (compact ? 22 : 46) * uiScale)

    Rectangle {
        id: frame
        anchors.fill: parent
        color: mouse.pressed ? Qt.rgba(0, 0.18, 0.05, 0.55) : Qt.rgba(0, 0.016, 0, 0.92)
        border.width: 1
        border.color: (button.activeFocus || mouse.containsMouse) ? button.bright : button.dim
        antialiasing: true

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: button.label
        color: (button.activeFocus || mouse.containsMouse) ? button.bright : button.dim
        font.family: button.fontFamily
        font.pixelSize: Math.round((button.compact ? 11 : 13) * button.uiScale)
        font.letterSpacing: 2 * button.uiScale

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            button.clicked();
            event.accepted = true;
        }
    }
}
