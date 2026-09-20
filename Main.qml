// Matrix Code Rain — an SDDM greeter theme.
//
// Layout: a full-screen animated glyph rain (MatrixRain.qml) behind a centred
// login panel (LoginPanel.qml), with compact power actions (PowerControls.qml)
// in the corner.
//
// Every colour, string and metric is read from theme.conf through SDDM's
// global `config` object exactly once, here, and handed to the sub-components
// as plain properties — so nothing below has to re-read or re-guard
// configuration, and the theme still renders with sane defaults if theme.conf
// is absent or incomplete (which is what happens under `--test-mode`).
import QtQuick

Rectangle {
    id: root

    // SDDM resizes the greeter to the screen. These values only matter to
    // `sddm-greeter-qt6 --test-mode`, which starts from the theme's own size.
    width: 1920
    height: 1080
    color: colorBackground

    // ---------------------------------------------------------------- config
    function cfgString(key, fallback) {
        var value = (typeof config === "undefined") ? undefined : config[key];
        if (value === undefined || value === null)
            return fallback;
        var text = String(value);
        return text.length === 0 ? fallback : text;
    }

    function cfgNumber(key, fallback) {
        var value = parseFloat(cfgString(key, ""));
        return isNaN(value) ? fallback : value;
    }

    function cfgBool(key, fallback) {
        var value = cfgString(key, "").toLowerCase();
        if (value.length === 0)
            return fallback;
        return value === "true" || value === "1" || value === "yes" || value === "on";
    }

    readonly property color colorBackground: cfgString("background", "#000000")
    // Primary Matrix green: text, borders, the login button.
    readonly property color colorBright: cfgString("accentColor", "#00FF41")
    // Supporting greens: labels, inactive borders, rain tails.
    readonly property color colorMid: cfgString("midColor", "#00C832")
    readonly property color colorDim: cfgString("dimColor", "#008F11")
    // The leading glyph of each rain stream.
    readonly property color colorHead: cfgString("rainHeadColor", "#CFFFD8")
    // Reserved for status text that must not read as "green means fine".
    readonly property color colorNeutral: cfgString("neutralColor", "#BFC6BF")

    // --------------------------------------------------------------- scaling
    // One factor drives every size in the theme, so 1080p, 1440p, ultrawide
    // and 4K all get the same proportions rather than a layout tuned to one
    // resolution. Clamped: the panel should not become a postage stamp on a
    // small screen, nor a billboard on a 4K one.
    readonly property real uiScale: Math.max(0.85, Math.min(1.75, height / 1080.0))

    // ------------------------------------------------------------------ font
    // Prefer the configured family, then common clean monospace faces, and
    // fall back to fontconfig's generic "monospace" so the theme never renders
    // in a proportional font on a machine that has none of them installed.
    readonly property string monoFamily: resolveMonoFamily()

    function resolveMonoFamily() {
        var available = Qt.fontFamilies();
        var wanted = [];
        var configured = cfgString("fontFamily", "");
        if (configured.length > 0)
            wanted.push(configured);
        wanted = wanted.concat(["JetBrainsMono Nerd Font Mono", "JetBrainsMono Nerd Font", "JetBrains Mono",
                                "FiraCode Nerd Font Mono", "Fira Code", "Hack Nerd Font Mono", "Hack",
                                "IBM Plex Mono", "Source Code Pro", "DejaVu Sans Mono", "Liberation Mono",
                                "Noto Sans Mono"]);
        for (var i = 0; i < wanted.length; ++i) {
            if (available.indexOf(wanted[i]) !== -1)
                return wanted[i];
        }
        return "monospace";
    }

    // ----------------------------------------------------------------- rain
    MatrixRain {
        id: rain
        anchors.fill: parent

        bodyColor: root.colorBright
        tailColor: root.colorDim
        headColor: root.colorHead
        fontFamily: root.monoFamily

        // Deliberately close to terminal size: dense thin streams rather than
        // movie-poster glyphs. Grows only gently with resolution.
        fontSize: Math.round(root.cfgNumber("rainFontSize", 13) * Math.max(1.0, Math.min(1.5, root.uiScale)))
        columnSpacing: fontSize * root.cfgNumber("rainColumnSpacing", 1.65)
        maxColumns: Math.round(root.cfgNumber("rainMaxColumns", 260))
        minSpeed: root.cfgNumber("rainMinSpeed", 45)
        maxSpeed: root.cfgNumber("rainMaxSpeed", 165)
        opacity: root.cfgNumber("rainOpacity", 0.85)
    }

    // ---------------------------------------------------------------- header
    Text {
        id: header
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: panel.top
        anchors.bottomMargin: 26 * root.uiScale

        text: {
            var configured = root.cfgString("headerText", "");
            if (configured.length > 0)
                return configured;
            var host = (typeof sddm !== "undefined" && sddm.hostName) ? String(sddm.hostName) : "";
            return host.length > 0 ? host.toUpperCase() + " // AUTHENTICATION" : "SYSTEM ACCESS";
        }
        visible: text.length > 0 && root.cfgBool("showHeader", true)

        color: root.colorMid
        font.family: root.monoFamily
        font.pixelSize: Math.round(15 * root.uiScale)
        font.letterSpacing: 3 * root.uiScale
        renderType: Text.QtRendering
    }

    // ----------------------------------------------------------------- panel
    LoginPanel {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        // Slightly below centre: the header sits in the gap above it, and the
        // pair reads as centred.
        y: Math.round((parent.height - height) / 2 + 18 * root.uiScale)

        uiScale: root.uiScale
        fontFamily: root.monoFamily
        bright: root.colorBright
        mid: root.colorMid
        dim: root.colorDim
        neutral: root.colorNeutral

        avatarSource: Qt.resolvedUrl(root.cfgString("avatar", "assets/pfp.png"))
        avatarDiameter: Math.round(root.cfgNumber("avatarSize", 120) * root.uiScale)
        showAvatar: root.cfgBool("showAvatar", true)
    }

    // -------------------------------------------------------- power controls
    PowerControls {
        id: power
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(28 * root.uiScale)

        visible: root.cfgBool("showPowerActions", true)
        uiScale: root.uiScale
        fontFamily: root.monoFamily
        bright: root.colorBright
        dim: root.colorDim
        allowSuspend: root.cfgBool("showSuspend", true)
        forceVisible: root.cfgString("powerVisibility", "auto") === "always"
    }

    Component.onCompleted: panel.takeFocus()
}
