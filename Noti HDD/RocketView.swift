import Cocoa

// Naro-1 silhouette reference: https://www.kari.re.kr/kor/contents/95
final class RocketView: NSView {
    var heading: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let side = min(bounds.width, bounds.height)
        guard side > 0 else { return }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = NSAffineTransform()
        transform.translateX(by: bounds.midX, yBy: bounds.midY)
        transform.rotate(byRadians: heading)
        transform.scale(by: side / 100)
        transform.translateX(by: -50, yBy: -50)
        transform.concat()

        func polygon(_ points: [NSPoint]) -> NSBezierPath {
            let path = NSBezierPath()
            guard let first = points.first else { return path }
            path.move(to: first)
            for point in points.dropFirst() { path.line(to: point) }
            path.close()
            return path
        }

        // A compact exhaust plume keeps the rocket visible on a black overlay.
        let flame = NSBezierPath()
        flame.move(to: NSPoint(x: 43, y: 18))
        flame.curve(to: NSPoint(x: 50, y: 3),
                    controlPoint1: NSPoint(x: 41, y: 12),
                    controlPoint2: NSPoint(x: 47, y: 7))
        flame.curve(to: NSPoint(x: 57, y: 18),
                    controlPoint1: NSPoint(x: 53, y: 7),
                    controlPoint2: NSPoint(x: 59, y: 12))
        flame.close()
        NSColor(calibratedRed: 1, green: 0.43, blue: 0.12, alpha: 1).setFill()
        flame.fill()
        NSColor(calibratedRed: 1, green: 0.86, blue: 0.43, alpha: 1).setFill()
        polygon([NSPoint(x: 46, y: 18), NSPoint(x: 50, y: 7), NSPoint(x: 54, y: 18)]).fill()

        // The narrow upper stage, tapered shoulder, and wider first stage.
        let body = polygon([
            NSPoint(x: 39, y: 20), NSPoint(x: 39, y: 33),
            NSPoint(x: 41, y: 36), NSPoint(x: 41, y: 66),
            NSPoint(x: 44, y: 72), NSPoint(x: 44, y: 83),
            NSPoint(x: 50, y: 96), NSPoint(x: 56, y: 83),
            NSPoint(x: 56, y: 72), NSPoint(x: 59, y: 66),
            NSPoint(x: 59, y: 36), NSPoint(x: 61, y: 33),
            NSPoint(x: 61, y: 20)
        ])
        NSGradient(colors: [NSColor(calibratedWhite: 0.72, alpha: 1),
                            .white, NSColor(calibratedWhite: 0.82, alpha: 1)])?
            .draw(in: body, angle: 0)
        NSColor(calibratedWhite: 0.48, alpha: 1).setStroke()
        body.lineWidth = 0.9
        body.stroke()

        NSColor(calibratedWhite: 0.35, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 41, y: 35, width: 18, height: 2)).fill()
        NSBezierPath(rect: NSRect(x: 44, y: 71, width: 12, height: 1.5)).fill()
        polygon([NSPoint(x: 45, y: 20), NSPoint(x: 43, y: 17),
                 NSPoint(x: 57, y: 17), NSPoint(x: 55, y: 20)]).fill()

        // A small red and blue Korean emblem, without details that blur at menu size.
        let flagCenter = NSPoint(x: 50, y: 64)
        for (start, end, color) in [(CGFloat(0), CGFloat(180), NSColor.systemRed),
                                    (CGFloat(180), CGFloat(360), NSColor.systemBlue)] {
            let half = NSBezierPath()
            half.appendArc(withCenter: flagCenter, radius: 3, startAngle: start, endAngle: end)
            half.close()
            color.setFill()
            half.fill()
        }

        if side >= 48 {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 3.8, weight: .bold),
                .foregroundColor: NSColor(calibratedWhite: 0.2, alpha: 1)
            ]
            for (index, letter) in "KOREA".enumerated() {
                let text = String(letter) as NSString
                let width = text.size(withAttributes: attributes).width
                text.draw(at: NSPoint(x: 50 - width / 2, y: 56 - CGFloat(index) * 4.5),
                          withAttributes: attributes)
            }
        }
    }
}
