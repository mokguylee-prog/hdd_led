import Cocoa

/// A single LED rounded-rect with bevel edge effect.
class LEDView: NSView {
    var color: NSColor = .systemGreen {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let inset: CGFloat = 3
        let radius: CGFloat = 5
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

        // Outer glow
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = color.withAlphaComponent(0.75)
        glow.shadowBlurRadius = 7
        glow.shadowOffset = .zero
        glow.set()
        color.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()

        // Base color fill
        color.setFill()
        path.fill()

        // Specular highlight (top half)
        let hlRect = NSRect(x: rect.minX + 3, y: rect.midY,
                            width: rect.width - 6, height: rect.height * 0.38)
        let hlPath = NSBezierPath(roundedRect: hlRect, xRadius: 3, yRadius: 3)
        NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.48),
            NSColor.white.withAlphaComponent(0.0)
        ])?.draw(in: hlPath, angle: -90)

        // ── Bevel edges ──────────────────────────────────────────
        // Top-left bright edge (light source from top-left)
        let topEdge = NSBezierPath()
        topEdge.move(to: NSPoint(x: rect.minX + radius, y: rect.maxY - 0.5))
        topEdge.line(to: NSPoint(x: rect.maxX - radius, y: rect.maxY - 0.5))
        topEdge.lineWidth = 1.0
        NSColor.white.withAlphaComponent(0.45).setStroke()
        topEdge.stroke()

        let leftEdge = NSBezierPath()
        leftEdge.move(to: NSPoint(x: rect.minX + 0.5, y: rect.maxY - radius))
        leftEdge.line(to: NSPoint(x: rect.minX + 0.5, y: rect.minY + radius))
        leftEdge.lineWidth = 1.0
        NSColor.white.withAlphaComponent(0.30).setStroke()
        leftEdge.stroke()

        // Bottom-right dark edge (shadow side)
        let bottomEdge = NSBezierPath()
        bottomEdge.move(to: NSPoint(x: rect.minX + radius, y: rect.minY + 0.5))
        bottomEdge.line(to: NSPoint(x: rect.maxX - radius, y: rect.minY + 0.5))
        bottomEdge.lineWidth = 1.0
        NSColor.black.withAlphaComponent(0.45).setStroke()
        bottomEdge.stroke()

        let rightEdge = NSBezierPath()
        rightEdge.move(to: NSPoint(x: rect.maxX - 0.5, y: rect.maxY - radius))
        rightEdge.line(to: NSPoint(x: rect.maxX - 0.5, y: rect.minY + radius))
        rightEdge.lineWidth = 1.0
        NSColor.black.withAlphaComponent(0.35).setStroke()
        rightEdge.stroke()

        // Outer border
        path.lineWidth = 0.8
        NSColor.black.withAlphaComponent(0.55).setStroke()
        path.stroke()
    }
}

/// Creates a status bar NSImage with a colored LED rounded-rect + bevel.
func makeLEDStatusImage(color: NSColor, size: CGFloat = 16) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let radius: CGFloat = 3.5
    let rect = NSRect(x: 1.5, y: 2.5, width: size - 3, height: size - 5)
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Glow
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color.withAlphaComponent(0.9)
    shadow.shadowBlurRadius = 4
    shadow.shadowOffset = .zero
    shadow.set()
    color.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Base fill
    color.setFill()
    path.fill()

    // Highlight
    let hlRect = NSRect(x: rect.minX + 1.5, y: rect.midY,
                        width: rect.width - 3, height: rect.height * 0.38)
    let hlPath = NSBezierPath(roundedRect: hlRect, xRadius: 2, yRadius: 2)
    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.52),
        NSColor.white.withAlphaComponent(0.0)
    ])?.draw(in: hlPath, angle: -90)

    // Bevel — top bright
    let top = NSBezierPath()
    top.move(to: NSPoint(x: rect.minX + radius, y: rect.maxY - 0.5))
    top.line(to: NSPoint(x: rect.maxX - radius, y: rect.maxY - 0.5))
    top.lineWidth = 0.8
    NSColor.white.withAlphaComponent(0.40).setStroke()
    top.stroke()

    // Bevel — bottom dark
    let bottom = NSBezierPath()
    bottom.move(to: NSPoint(x: rect.minX + radius, y: rect.minY + 0.5))
    bottom.line(to: NSPoint(x: rect.maxX - radius, y: rect.minY + 0.5))
    bottom.lineWidth = 0.8
    NSColor.black.withAlphaComponent(0.40).setStroke()
    bottom.stroke()

    // Outer border
    path.lineWidth = 0.75
    NSColor.black.withAlphaComponent(0.55).setStroke()
    path.stroke()

    image.unlockFocus()
    image.isTemplate = false
    return image
}
