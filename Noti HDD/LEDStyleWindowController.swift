import Cocoa

enum LEDStyle: Int, CaseIterable {
    case greenRed = 0
    case greenOrange = 1
    case orangeRed = 2
    case redGreen = 3
    case greenGray = 4

    var activeColor: NSColor {
        switch self {
        case .greenRed:    return NSColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1)
        case .greenOrange: return NSColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1)
        case .orangeRed:   return NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1)
        case .redGreen:    return NSColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        case .greenGray:   return NSColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1)
        }
    }

    var inactiveColor: NSColor {
        switch self {
        case .greenRed:    return NSColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        case .greenOrange: return NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1)
        case .orangeRed:   return NSColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        case .redGreen:    return NSColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1)
        case .greenGray:   return NSColor(white: 0.45, alpha: 1)
        }
    }
}

class LEDStyleWindowController: NSWindowController {
    private enum Layout {
        static let baseWidth: CGFloat = 460
        static let baseHeight: CGFloat = 390
        static let widthScale: CGFloat = 0.5
        static let heightScale: CGFloat = 0.7
        static let windowWidth: CGFloat = baseWidth * widthScale
        static let windowHeight: CGFloat = baseHeight * heightScale
        static let ledPreviewInset: CGFloat = 3
        static let ledPreviewBaseSize: CGFloat = 30
        static let radioSize: CGFloat = 40
    }

    var onStyleSelected: ((LEDStyle) -> Void)?
    var currentStyle: LEDStyle = .greenRed

    private var radioButtons: [StyleRadioView] = []
    private var rowBackgrounds: [StyleRowView] = []

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Layout.windowWidth, height: Layout.windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Noti Style"
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(white: 0.12, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        self.init(window: window)
        setupContentView()
    }

    private func setupContentView() {
        guard let contentView = window?.contentView else { return }

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(white: 0.12, alpha: 1.0).cgColor

        let scaledView = NSView(frame: contentView.bounds)
        scaledView.autoresizingMask = [.width, .height]
        scaledView.wantsLayer = true
        scaledView.layer?.backgroundColor = NSColor(white: 0.12, alpha: 1.0).cgColor
        // Keep the existing 460x390 layout and let AppKit scale it into the smaller window.
        scaledView.bounds = NSRect(x: 0, y: 0, width: Layout.baseWidth, height: Layout.baseHeight)
        contentView.addSubview(scaledView)

        // Title
        let titleLabel = makeLabel("NOTI STYLE", size: 22, weight: .bold, color: .white)
        titleLabel.frame = NSRect(x: 0, y: 350, width: 460, height: 36)
        titleLabel.alignment = .center
        scaledView.addSubview(titleLabel)

        // Divider
        let divider = NSBox()
        divider.frame = NSRect(x: 20, y: 342, width: 420, height: 1)
        divider.boxType = .separator
        divider.borderColor = NSColor(white: 0.3, alpha: 1)
        scaledView.addSubview(divider)

        // 5 rows with slightly tighter spacing so the new option fits in the same window.
        let rowHeight: CGFloat = 60
        let startY: CGFloat = 278

        for (i, style) in LEDStyle.allCases.enumerated() {
            let y = startY - CGFloat(i) * rowHeight
            addStyleRow(to: scaledView, style: style, y: y, index: i)
        }
    }

    private func addStyleRow(to view: NSView, style: LEDStyle, y: CGFloat, index: Int) {
        // Row background (clickable, highlight when selected)
        let rowBg = StyleRowView(frame: NSRect(x: 15, y: y + 4, width: 430, height: 52))
        rowBg.styleIndex = index
        rowBg.isSelected = (style == currentStyle)
        rowBg.onSelect = { [weak self] in self?.selectStyle(style) }
        view.addSubview(rowBg)
        rowBackgrounds.append(rowBg)

        let cy = y + 16  // center y for content inside row

        // "Activity" label
        let actLabel = makeLabel("Act", size: 24, weight: .semibold, color: NSColor(white: 0.75, alpha: 1))
        actLabel.sizeToFit()
        actLabel.frame = NSRect(x: 30, y: cy - 2, width: max(68, actLabel.frame.width), height: actLabel.frame.height)
        view.addSubview(actLabel)

        // Arrow ←
        let arrowLeft = makeLabel("←", size: 18, weight: .light, color: NSColor(white: 0.55, alpha: 1))
        arrowLeft.frame = NSRect(x: 104, y: cy, width: 24, height: 24)
        view.addSubview(arrowLeft)

        // Active LED
        let activeLED = LEDView(
            frame: NSRect(
                x: 134 + Layout.ledPreviewInset,
                y: cy - 2 + Layout.ledPreviewInset,
                width: Layout.ledPreviewBaseSize - (Layout.ledPreviewInset * 2),
                height: Layout.ledPreviewBaseSize - (Layout.ledPreviewInset * 2)
            )
        )
        activeLED.color = style.activeColor
        view.addSubview(activeLED)

        // Separator dot
        let dot = makeLabel("·", size: 22, weight: .regular, color: NSColor(white: 0.45, alpha: 1))
        dot.frame = NSRect(x: 170, y: cy - 1, width: 20, height: 26)
        dot.alignment = .center
        view.addSubview(dot)

        // Inactive LED
        let inactiveLED = LEDView(
            frame: NSRect(
                x: 194 + Layout.ledPreviewInset,
                y: cy - 2 + Layout.ledPreviewInset,
                width: Layout.ledPreviewBaseSize - (Layout.ledPreviewInset * 2),
                height: Layout.ledPreviewBaseSize - (Layout.ledPreviewInset * 2)
            )
        )
        inactiveLED.color = style.inactiveColor
        view.addSubview(inactiveLED)

        // Arrow →
        let arrowRight = makeLabel("→", size: 18, weight: .light, color: NSColor(white: 0.55, alpha: 1))
        arrowRight.frame = NSRect(x: 230, y: cy, width: 24, height: 24)
        view.addSubview(arrowRight)

        // "Inactivity" label
        let inactLabel = makeLabel("InAct", size: 24, weight: .semibold, color: NSColor(white: 0.75, alpha: 1))
        inactLabel.sizeToFit()
        inactLabel.frame = NSRect(x: 260, y: cy - 2, width: max(80, inactLabel.frame.width), height: inactLabel.frame.height)
        view.addSubview(inactLabel)

        // Selection button
        let radio = StyleRadioView(frame: NSRect(x: 388, y: y + 10, width: Layout.radioSize, height: Layout.radioSize))
        radio.styleIndex = index
        radio.isSelected = (style == currentStyle)
        radio.onSelect = { [weak self] in self?.selectStyle(style) }
        view.addSubview(radio)
        radioButtons.append(radio)
    }

    private func selectStyle(_ style: LEDStyle) {
        currentStyle = style
        onStyleSelected?(style)

        for (i, btn) in radioButtons.enumerated() {
            btn.isSelected = (i == style.rawValue)
            btn.needsDisplay = true
        }
        for rowBg in rowBackgrounds {
            rowBg.isSelected = (rowBg.styleIndex == style.rawValue)
            rowBg.needsDisplay = true
        }
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        return label
    }
}

// Clickable row background with selection highlight
class StyleRowView: NSView {
    var styleIndex: Int = 0
    var isSelected: Bool = false
    var onSelect: (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        if isSelected {
            NSColor(white: 0.22, alpha: 1).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?()
    }
}

class StyleRadioView: NSView {
    var styleIndex: Int = 0
    var isSelected: Bool = false
    var onSelect: (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        let outerRect = bounds.insetBy(dx: 5, dy: 5)
        let outerPath = NSBezierPath(ovalIn: outerRect)

        NSColor(white: 0.18, alpha: 1).setFill()
        outerPath.fill()

        NSColor(white: 0.85, alpha: 1).setStroke()
        outerPath.lineWidth = 3
        outerPath.stroke()

        if isSelected {
            let innerRect = outerRect.insetBy(dx: 9, dy: 9)
            let innerPath = NSBezierPath(ovalIn: innerRect)
            NSColor.systemBlue.setFill()
            innerPath.fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?()
    }
}
