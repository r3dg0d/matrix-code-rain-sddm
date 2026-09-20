// The login panel: avatar, user, password, session, submit, status.
//
// The panel paints a nearly-opaque black card so the rain never competes with
// the controls, and every control keeps to the black/green palette.
import QtQuick
import "components" as Components

Item {
    id: panel

    property real uiScale: 1.0
    property string fontFamily: "monospace"
    property color bright: "#00FF41"
    property color mid: "#00C832"
    property color dim: "#008F11"
    property color neutral: "#BFC6BF"

    property url avatarSource
    property real avatarDiameter: 120
    property bool showAvatar: true

    readonly property bool hasSddm: typeof sddm !== "undefined"
    property bool busy: false

    width: Math.round(420 * uiScale)
    height: card.height

    // ------------------------------------------------------------------ card
    Rectangle {
        id: card
        width: parent.width
        height: content.height + content.anchors.topMargin * 2
        color: Qt.rgba(0, 0.012, 0, 0.88)
        border.width: 1
        border.color: panel.dim
        antialiasing: true
    }

    Column {
        id: content
        anchors.top: card.top
        anchors.topMargin: Math.round(28 * panel.uiScale)
        anchors.left: card.left
        anchors.right: card.right
        anchors.leftMargin: Math.round(30 * panel.uiScale)
        anchors.rightMargin: Math.round(30 * panel.uiScale)
        spacing: Math.round(14 * panel.uiScale)

        Components.Avatar {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: panel.showAvatar
            source: panel.avatarSource
            diameter: panel.avatarDiameter
            ring: panel.mid
        }

        Item {
            width: 1
            height: Math.round(4 * panel.uiScale)
        }

        // ------------------------------------------------------------- user
        // A free-text field, pre-filled with the last account to log in, so
        // any valid local account can still sign in. When the machine has more
        // than one visible account, the selector below replaces it.
        Components.MatrixField {
            id: userField
            width: parent.width
            visible: !userSelect.visible
            label: "USER"
            placeholder: "username"
            uiScale: panel.uiScale
            fontFamily: panel.fontFamily
            bright: panel.bright
            mid: panel.mid
            dim: panel.dim
            onAccepted: passwordField.forceActiveFocus()
        }

        Components.MatrixSelect {
            id: userSelect
            width: parent.width
            visible: count > 1
            label: "USER"
            model: panel.hasSddm ? userModel : null
            textRole: "name"
            uiScale: panel.uiScale
            fontFamily: panel.fontFamily
            bright: panel.bright
            mid: panel.mid
            dim: panel.dim
            onActivated: passwordField.text = ""
        }

        // --------------------------------------------------------- password
        Components.MatrixField {
            id: passwordField
            width: parent.width
            label: "PASS"
            echoMode: TextInput.Password
            uiScale: panel.uiScale
            fontFamily: panel.fontFamily
            bright: panel.bright
            mid: panel.mid
            dim: panel.dim
            onAccepted: panel.attemptLogin()
        }

        // ---------------------------------------------------------- session
        Components.MatrixSelect {
            id: sessionSelect
            width: parent.width
            label: "SESSION"
            model: panel.hasSddm ? sessionModel : null
            textRole: "name"
            uiScale: panel.uiScale
            fontFamily: panel.fontFamily
            bright: panel.bright
            mid: panel.mid
            dim: panel.dim
        }

        Item {
            width: 1
            height: Math.round(2 * panel.uiScale)
        }

        Components.MatrixButton {
            id: loginButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(160 * panel.uiScale)
            label: panel.busy ? "..." : "LOGIN"
            uiScale: panel.uiScale
            fontFamily: panel.fontFamily
            bright: panel.bright
            dim: panel.dim
            onClicked: panel.attemptLogin()
        }

        // Status line. Reserved height, so the panel does not resize — and
        // jump under the pointer — the first time a login fails.
        Text {
            id: status
            width: parent.width
            height: Math.round(18 * panel.uiScale)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: ""
            color: panel.neutral
            font.family: panel.fontFamily
            font.pixelSize: Math.round(11 * panel.uiScale)
            font.letterSpacing: 1.5 * panel.uiScale
        }

        Item {
            width: 1
            height: Math.round(6 * panel.uiScale)
        }
    }

    // ----------------------------------------------------------------- logic
    function currentUser() {
        return userSelect.visible ? userSelect.currentText : userField.text;
    }

    function attemptLogin() {
        var user = currentUser();
        if (user.length === 0) {
            status.text = "ENTER A USERNAME";
            (userSelect.visible ? userSelect : userField).forceActiveFocus();
            return;
        }
        if (!hasSddm) {
            status.text = "TEST MODE — NO LOGIN BACKEND";
            return;
        }
        panel.busy = true;
        status.text = "AUTHENTICATING";
        sddm.login(user, passwordField.text, sessionSelect.currentIndex);
    }

    function takeFocus() {
        passwordField.forceActiveFocus();
    }

    Connections {
        target: panel.hasSddm ? sddm : null
        ignoreUnknownSignals: true

        function onLoginSucceeded() {
            panel.busy = false;
            status.text = "ACCESS GRANTED";
        }

        function onLoginFailed() {
            panel.busy = false;
            status.text = "ACCESS DENIED";
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }
    }

    // Seed the controls from SDDM's own models once they exist: the last
    // account that logged in, and the session it used.
    Component.onCompleted: {
        if (hasSddm) {
            // The last account to log in; on a machine that has never seen a
            // login, the first account SDDM is willing to show.
            var last = userModel.lastUser ? String(userModel.lastUser) : "";
            if (last.length === 0 && userSelect.count > 0)
                last = userSelect.itemText(0);
            userField.text = last;
            if (userSelect.count > 0) {
                var wanted = Math.max(0, userSelect.indexOfName(last));
                userSelect.setIndex(wanted);
            }
            if (sessionSelect.count > 0)
                sessionSelect.setIndex(Math.max(0, Math.min(sessionModel.lastIndex, sessionSelect.count - 1)));
        }
    }
}
