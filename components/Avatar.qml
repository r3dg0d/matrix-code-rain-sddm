// Circular profile image with a thin green ring.
//
// Canvas rather than QtQuick.Effects' MultiEffect mask: the image is painted
// exactly once (on load and on resize), it needs no effects module, and
// `clip: true` on a rounded Rectangle would not have worked — Qt clips to the
// bounding box, not to the radius.
import QtQuick

Item {
    id: avatar

    property url source
    property real diameter: 120
    property color ring: "#00FF41"
    property color fill: "#020502"
    property real ringWidth: Math.max(1, Math.round(diameter * 0.012))

    implicitWidth: diameter
    implicitHeight: diameter
    width: diameter
    height: diameter

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.save();
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, Math.max(0, width / 2 - avatar.ringWidth), 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.clip();

            ctx.fillStyle = avatar.fill;
            ctx.fillRect(0, 0, width, height);

            if (String(avatar.source).length > 0 && isImageLoaded(avatar.source))
                ctx.drawImage(avatar.source, 0, 0, width, height);

            ctx.restore();
        }

        onImageLoaded: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: avatar.reload()
    }

    onSourceChanged: reload()

    function reload() {
        if (String(source).length === 0)
            return;
        if (canvas.isImageLoaded(source))
            canvas.requestPaint();
        else if (!canvas.isImageLoading(source))
            canvas.loadImage(source);
    }

    // The ring, drawn as a real rounded Rectangle so it stays crisp at any
    // size without the Canvas having to repaint.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: avatar.ring
        border.width: avatar.ringWidth
        antialiasing: true
    }
}
