// A single labelled input row: "USER  [ neo            ]".
//
// Plain QtQuick rather than QtQuick.Controls, so the theme depends only on the
// QML module every SDDM Qt build already ships, and every border, colour and
// focus state is the theme's own rather than a restyled control.
import QtQuick

FocusScope {
    id: field

    property string label: ""
    property alias text: input.text
    property alias echoMode: input.echoMode
    property alias placeholder: placeholderText.text
    property bool readOnlyField: false
    // Draw the focused state even though the focus is held by a parent — what
    // MatrixSelect needs, since it keeps key handling to itself.
    property bool highlighted: false

    property real uiScale: 1.0
    property string fontFamily: "monospace"
    property color bright: "#00FF41"
    property color mid: "#00C832"
    property color dim: "#008F11"

    // Whether the inner input holds the keyboard focus — what a parent should
    // watch, since the focus lands on the input, not on this FocusScope.
    readonly property alias inputFocused: input.activeFocus

    // Space kept clear at the right edge of the box for whatever the parent
    // draws there — MatrixSelect's dropdown caret, for instance.
    property real rightInset: 0

    signal accepted()
    // Key presses seen by the input itself, forwarded before TextInput's own
    // handling. MatrixSelect drives its dropdown from these: whichever item
    // holds the active focus is the only one Qt delivers key events to.
    signal keyPressed(var event)

    implicitHeight: Math.round(34 * uiScale)
    implicitWidth: Math.round(320 * uiScale)

    readonly property real labelWidth: Math.round(74 * uiScale)

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: field.labelWidth
        text: field.label
        color: field.dim
        font.family: field.fontFamily
        font.pixelSize: Math.round(12 * field.uiScale)
        font.letterSpacing: 1.5 * field.uiScale
    }

    Rectangle {
        id: box
        anchors.left: labelText.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        // Nearly black, so the rain never shows through the text.
        color: Qt.rgba(0, 0.016, 0, 0.92)
        border.width: 1
        border.color: (field.activeFocus || field.highlighted) ? field.bright : field.dim
        antialiasing: true

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        // Focus marker: a solid caret block in the left gutter, the way a
        // terminal marks the active line.
        Rectangle {
            id: marker
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(7 * field.uiScale)
            width: Math.round(6 * field.uiScale)
            height: Math.round(2 * field.uiScale)
            color: field.bright
            opacity: (field.activeFocus || field.highlighted) ? 1.0 : 0.35
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Math.round(20 * field.uiScale)
            anchors.rightMargin: Math.round((12 + field.rightInset) * field.uiScale)
            verticalAlignment: TextInput.AlignVCenter

            focus: true
            readOnly: field.readOnlyField
            activeFocusOnPress: !field.readOnlyField
            selectByMouse: !field.readOnlyField
            clip: true

            color: field.bright
            selectionColor: field.dim
            selectedTextColor: "#000000"
            font.family: field.fontFamily
            font.pixelSize: Math.round(14 * field.uiScale)
            passwordCharacter: "•"
            passwordMaskDelay: 0

            onAccepted: field.accepted()
            Keys.onPressed: function (event) {
                field.keyPressed(event);
            }

            Text {
                id: placeholderText
                anchors.verticalCenter: parent.verticalCenter
                color: field.dim
                font: input.font
                visible: input.text.length === 0 && !input.activeFocus
            }
        }
    }

    function selectAllText() {
        input.selectAll();
    }
}
