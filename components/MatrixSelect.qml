// A labelled dropdown over any QAbstractItemModel role — used for the session
// chooser and, when the machine has more than one account, the user chooser.
//
// Built from MatrixField plus a list overlay rather than QtQuick.Controls'
// ComboBox: same reasoning as MatrixField, and it keeps the closed state
// pixel-identical to the text fields above it.
pragma ComponentBehavior: Bound

import QtQuick
import "." as Components

// A plain Item wrapping a read-only MatrixField.
//
// Keyboard focus can legitimately land in two places here — on this item (it
// is in the tab chain) or on the field's read-only input (a click puts it
// there) — and Qt delivers key events only to whichever one actually holds it.
// So both are wired to the same handler rather than betting on one.
Item {
    id: select

    property string label: ""
    property var model: null
    // Model role to display. SDDM's userModel and sessionModel both expose
    // the human-readable entry as "name".
    property string textRole: "name"
    property int currentIndex: 0
    property string currentText: ""

    property real uiScale: 1.0
    property string fontFamily: "monospace"
    property color bright: "#00FF41"
    property color mid: "#00C832"
    property color dim: "#008F11"

    property bool expanded: false
    readonly property int visibleRows: 6

    // Rise above the siblings below it in the panel while the list is open;
    // the dropdown is drawn outside this item's own bounds.
    z: expanded ? 100 : 0

    activeFocusOnTab: true

    // True while the field's input has the keyboard focus.
    readonly property alias fieldFocused: field.inputFocused
    // ...and true whenever the control is focused at all, either way.
    readonly property bool focused: activeFocus || fieldFocused

    implicitHeight: field.implicitHeight
    implicitWidth: field.implicitWidth

    signal activated(int index)

    readonly property int count: probe.count

    // SDDM's models are C++ list models: a ListView delegate is handed the
    // role directly, but reading one outside a view needs a lookup. The hidden
    // Repeater below does that once per row and reports the text here.
    property var textCache: ({})

    function cacheText(index, text) {
        textCache[index] = text;
        if (index === currentIndex)
            currentText = text;
    }

    function itemText(index) {
        var text = textCache[index];
        return text === undefined ? "" : text;
    }

    // -1 when the name is not in the model.
    function indexOfName(name) {
        for (var i = 0; i < probe.count; ++i) {
            if (itemText(i) === name)
                return i;
        }
        return -1;
    }

    // Move the selection without closing the list — what the arrow keys do.
    function setIndex(index) {
        if (index < 0 || index >= probe.count)
            return;
        currentIndex = index;
        currentText = itemText(index);
        select.activated(index);
    }

    function selectIndex(index) {
        setIndex(index);
        expanded = false;
    }

    // An off-screen Repeater over the same model, purely so the closed field
    // can show the current row's text without duplicating SDDM's role names.
    Repeater {
        id: probe
        model: select.model
        delegate: Item {
            id: probeRow
            required property var model
            required property int index
            visible: false
            readonly property string roleText: {
                var value = probeRow.model[select.textRole];
                return value === undefined ? "" : String(value);
            }
            onRoleTextChanged: select.cacheText(probeRow.index, roleText)
            Component.onCompleted: select.cacheText(probeRow.index, roleText)
        }
    }

    Components.MatrixField {
        id: field
        anchors.fill: parent

        label: select.label
        text: select.currentText
        readOnlyField: true
        rightInset: 16
        uiScale: select.uiScale
        fontFamily: select.fontFamily
        bright: select.bright
        mid: select.mid
        dim: select.dim
        focus: true
        highlighted: select.activeFocus
        onKeyPressed: function (event) {
            select.handleKey(event);
        }
    }

    Keys.onPressed: function (event) {
        select.handleKey(event);
    }

    // Caret. Rotates when the list is open.
    Text {
        anchors.right: parent.right
        anchors.rightMargin: Math.round(10 * select.uiScale)
        anchors.verticalCenter: field.verticalCenter
        text: "▾"
        color: select.expanded || select.focused ? select.bright : select.dim
        font.family: select.fontFamily
        font.pixelSize: Math.round(12 * select.uiScale)
        rotation: select.expanded ? 180 : 0
        Behavior on rotation {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            field.forceActiveFocus();
            select.expanded = !select.expanded;
        }
    }

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Down:
            select.setIndex(Math.min(select.currentIndex + 1, select.count - 1));
            event.accepted = true;
            break;
        case Qt.Key_Up:
            select.setIndex(Math.max(select.currentIndex - 1, 0));
            event.accepted = true;
            break;
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            select.expanded = !select.expanded;
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            select.expanded = false;
            event.accepted = true;
            break;
        }
    }

    // ------------------------------------------------------------- dropdown
    Rectangle {
        id: popup
        anchors.top: parent.bottom
        anchors.topMargin: Math.round(4 * select.uiScale)
        anchors.left: parent.left
        anchors.leftMargin: field.labelWidth
        anchors.right: parent.right
        height: Math.min(listView.count, select.visibleRows) * rowHeight + 2
        visible: select.expanded
        z: 50

        readonly property real rowHeight: Math.round(28 * select.uiScale)

        color: Qt.rgba(0, 0.016, 0, 0.97)
        border.width: 1
        border.color: select.bright

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 1
            model: select.model
            clip: true
            currentIndex: select.currentIndex
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row
                required property int index
                required property var model
                width: ListView.view.width
                height: popup.rowHeight
                color: hover.containsMouse || row.index === select.currentIndex
                       ? Qt.rgba(0, 0.22, 0.07, 0.75)
                       : "transparent"

                readonly property string rowText: {
                    var value = row.model[select.textRole];
                    return value === undefined ? "" : String(value);
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(12 * select.uiScale)
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(8 * select.uiScale)
                    elide: Text.ElideRight
                    text: row.rowText
                    color: row.index === select.currentIndex ? select.bright : select.mid
                    font.family: select.fontFamily
                    font.pixelSize: Math.round(13 * select.uiScale)
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: select.selectIndex(row.index)
                }
            }
        }
    }

    onFocusedChanged: {
        if (!focused)
            expanded = false;
    }
}
