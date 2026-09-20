// Compact power actions. Text buttons rather than icon tiles: this sits in a
// screen corner and should read as a status line, not a toolbar.
import QtQuick
import "components" as Components

Row {
    id: power

    property real uiScale: 1.0
    property string fontFamily: "monospace"
    property color bright: "#00FF41"
    property color dim: "#008F11"
    property bool allowSuspend: true
    // theme.conf's powerVisibility=always. The capability flags come from the
    // SDDM daemon; a greeter started without one (--test-mode) reports none,
    // which would otherwise hide every action.
    property bool forceVisible: false

    // `sddm` is absent in a bare `qml` preview of this file; every capability
    // check degrades to "available" so the layout can still be inspected.
    readonly property bool hasSddm: typeof sddm !== "undefined"

    spacing: Math.round(10 * uiScale)

    Components.MatrixButton {
        label: "SUSPEND"
        compact: true
        visible: power.allowSuspend && (power.forceVisible || !power.hasSddm || sddm.canSuspend)
        uiScale: power.uiScale
        fontFamily: power.fontFamily
        bright: power.bright
        dim: power.dim
        onClicked: {
            if (power.hasSddm)
                sddm.suspend();
        }
    }

    Components.MatrixButton {
        label: "REBOOT"
        compact: true
        visible: power.forceVisible || !power.hasSddm || sddm.canReboot
        uiScale: power.uiScale
        fontFamily: power.fontFamily
        bright: power.bright
        dim: power.dim
        onClicked: {
            if (power.hasSddm)
                sddm.reboot();
        }
    }

    Components.MatrixButton {
        label: "SHUTDOWN"
        compact: true
        visible: power.forceVisible || !power.hasSddm || sddm.canPowerOff
        uiScale: power.uiScale
        fontFamily: power.fontFamily
        bright: power.bright
        dim: power.dim
        onClicked: {
            if (power.hasSddm)
                sddm.powerOff();
        }
    }
}
