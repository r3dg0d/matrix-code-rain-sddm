// Animated Matrix-style glyph rain.
//
// Performance strategy — the greeter may sit on this screen for hours, so the
// rain is built to be cheap and steady rather than clever:
//
//   * Each stream is three scene-graph items (tail text, fade overlay, head
//     glyph), created once by a Repeater. Nothing is instantiated per frame.
//   * Motion is a single NumberAnimation per stream on `y`. That is a
//     transform the scene graph animates without running JavaScript, which is
//     what keeps this at display refresh rate for ~150 streams.
//   * The progressive fade is a black-to-transparent gradient painted over
//     the tail, not per-glyph colours. One quad replaces what would otherwise
//     be a separately coloured Text item per character.
//   * Glyph churn is one shared low-frequency Timer that rewrites a few
//     random glyphs per tick, not a timer per stream.
// `ComponentBehavior: Bound` makes the delegates below bind the outer `rain`
// id explicitly, which is both what Qt 6 wants and measurably cheaper than
// resolving it through the context object on every access.
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: rain

    property color bodyColor: "#00FF41"
    property color tailColor: "#008F11"
    property color headColor: "#CFFFD8"
    property string fontFamily: "monospace"

    property int fontSize: 13
    property real columnSpacing: fontSize * 1.65
    property int maxColumns: 260
    // Pixels per second, randomised per stream and per cycle.
    property real minSpeed: 45
    property real maxSpeed: 165
    property bool running: true

    clip: true

    // Katakana (the Matrix's own alphabet), digits, a few Latin capitals and
    // symbols — weighted towards Katakana by simple repetition.
    readonly property var glyphs: (
        "ｦｧｨｩｪｫｬｭｮｯｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ" +
        "ｦｧｨｩｪｫｬｭｮｯｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ" +
        "0123456789012345789" +
        "ABCDEFGHJKLMNPQRSTUVWXYZ" +
        "+-*/<>=:;.#$%&@?!|"
    ).split("")

    function randomGlyph() {
        return glyphs[Math.floor(Math.random() * glyphs.length)];
    }

    readonly property real cellHeight: Math.round(fontSize * 1.14)
    readonly property int columnCount: Math.max(1, Math.min(maxColumns, Math.floor(width / Math.max(1, columnSpacing))))

    // Streams register themselves in this plain array so the churn timer can
    // reach them without walking the item tree every tick. It is mutated in
    // place on purpose: nothing binds to it.
    readonly property var streams: []

    Repeater {
        id: repeater
        model: rain.columnCount

        delegate: Item {
            id: stream
            required property int index

            width: rain.columnSpacing
            // A little horizontal jitter, so the columns do not read as a
            // perfectly regular grid.
            x: Math.round(index * rain.columnSpacing + jitter)
            height: Math.max(1, glyphCount * rain.cellHeight)

            property real jitter: 0
            property int glyphCount: 12
            property string tail: ""
            property string head: "ﾊ"
            property real speed: 90
            // Both are plain values set by reseed()/prepare(), never bindings:
            // an animation duration that re-evaluates while the animation runs
            // restarts it.
            property int fallDuration: 4000
            property int gapDuration: 0

            function reseed(firstRun) {
                jitter = (Math.random() - 0.5) * rain.columnSpacing * 0.35;
                glyphCount = 6 + Math.floor(Math.random() * 22);
                speed = rain.minSpeed + Math.random() * Math.max(1, rain.maxSpeed - rain.minSpeed);
                gapDuration = Math.round(Math.random() * 600);

                var parts = [];
                for (var i = 0; i < glyphCount - 1; ++i)
                    parts.push(rain.randomGlyph());
                tail = parts.join("\n");
                head = rain.randomGlyph();

                // The first cycle starts somewhere mid-screen, so the field is
                // already full when the greeter appears instead of raining in
                // from the top in one visible wave.
                y = firstRun ? Math.random() * rain.height - height
                             : -height;
            }

            // Distance left to travel, at this stream's own speed. Recomputed
            // immediately before each fall so it also covers the first cycle
            // and any screen-geometry change SDDM makes after startup.
            function prepare() {
                fallDuration = Math.max(600, Math.round(((rain.height - y) / Math.max(1, speed)) * 1000));
            }

            // Replace one glyph in place — the flicker that makes a stream
            // look like running code rather than a scrolling sprite.
            function churn() {
                if (glyphCount < 2)
                    return;
                if (Math.random() < 0.25) {
                    head = rain.randomGlyph();
                    return;
                }
                var parts = tail.split("\n");
                parts[Math.floor(Math.random() * parts.length)] = rain.randomGlyph();
                tail = parts.join("\n");
            }

            Text {
                id: tailText
                width: parent.width
                text: stream.tail
                color: rain.bodyColor
                font.family: rain.fontFamily
                font.pixelSize: rain.fontSize
                lineHeight: rain.cellHeight
                lineHeightMode: Text.FixedHeight
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.QtRendering
            }

            // The progressive fade: opaque black at the top of the tail,
            // transparent at the head. Over the theme's black background this
            // reads as each glyph dimming with age.
            Rectangle {
                anchors.fill: tailText
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.97) }
                    GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.72) }
                    GradientStop { position: 0.62; color: Qt.rgba(0, 0, 0, 0.34) }
                    GradientStop { position: 0.85; color: Qt.rgba(0, 0, 0, 0.06) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
                }
            }

            // Leading glyph, marginally brighter than the stream behind it.
            Text {
                width: parent.width
                y: Math.max(0, (stream.glyphCount - 1) * rain.cellHeight)
                text: stream.head
                color: rain.headColor
                font.family: rain.fontFamily
                font.pixelSize: rain.fontSize
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.QtRendering
            }

            SequentialAnimation {
                running: rain.running && rain.height > 0
                loops: Animation.Infinite

                ScriptAction { script: stream.prepare() }
                NumberAnimation {
                    target: stream
                    property: "y"
                    to: rain.height
                    duration: stream.fallDuration
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: stream.gapDuration }
                ScriptAction { script: stream.reseed(false) }
            }

            Component.onCompleted: {
                reseed(true);
                rain.streams.push(stream);
            }
            Component.onDestruction: {
                var at = rain.streams.indexOf(stream);
                if (at !== -1)
                    rain.streams.splice(at, 1);
            }
        }
    }

    // Shared glyph churn. One timer, a handful of mutations per tick: enough
    // flicker to look alive, far below the cost of animating every character.
    Timer {
        interval: 80
        repeat: true
        running: rain.running && rain.columnCount > 0
        onTriggered: {
            var count = rain.streams.length;
            if (count === 0)
                return;
            var mutations = Math.max(1, Math.round(count / 12));
            for (var i = 0; i < mutations; ++i)
                rain.streams[Math.floor(Math.random() * count)].churn();
        }
    }
}
