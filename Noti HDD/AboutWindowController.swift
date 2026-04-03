import Cocoa

class AboutWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Noti HDD"
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(white: 0.10, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        self.init(window: window)
        setupContentView()
    }

    private func setupContentView() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(white: 0.10, alpha: 1.0).cgColor

        // Disk icon (drawn programmatically)
        let diskIcon = DiskIconView(frame: NSRect(x: 170, y: 170, width: 80, height: 80))
        contentView.addSubview(diskIcon)

        // App name
        let nameLabel = NSTextField(labelWithString: "Noti HDD")
        nameLabel.font = NSFont(name: "Chalkduster", size: 28) ?? NSFont.boldSystemFont(ofSize: 28)
        nameLabel.textColor = .white
        nameLabel.backgroundColor = .clear
        nameLabel.frame = NSRect(x: 0, y: 130, width: 420, height: 40)
        nameLabel.alignment = .center
        contentView.addSubview(nameLabel)

        // Subtitle
        let subLabel = NSTextField(labelWithString: "& Eye rest!!")
        subLabel.font = NSFont.systemFont(ofSize: 11, weight: .light)
        subLabel.textColor = NSColor(white: 0.6, alpha: 1)
        subLabel.backgroundColor = .clear
        subLabel.frame = NSRect(x: 0, y: 108, width: 420, height: 20)
        subLabel.alignment = .center
        contentView.addSubview(subLabel)

        // Color bar at bottom (red/yellow/green/blue)
        let colors: [(NSColor, CGFloat)] = [
            (NSColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1), 0),
            (NSColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1), 105),
            (NSColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1), 210),
            (NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1), 315)
        ]
        for (color, x) in colors {
            let bar = NSView(frame: NSRect(x: x, y: 0, width: 105, height: 6))
            bar.wantsLayer = true
            bar.layer?.backgroundColor = color.cgColor
            contentView.addSubview(bar)
        }

        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = NSColor(white: 0.5, alpha: 1)
        versionLabel.backgroundColor = .clear
        versionLabel.frame = NSRect(x: 0, y: 80, width: 420, height: 20)
        versionLabel.alignment = .center
        contentView.addSubview(versionLabel)

        // Description
        let desc = NSTextField(wrappingLabelWithString:
            "Noti HDD monitors disk read/write activity and\ndisplays it as a status bar indicator.")
        desc.font = NSFont.systemFont(ofSize: 12)
        desc.textColor = NSColor(white: 0.65, alpha: 1)
        desc.backgroundColor = .clear
        desc.frame = NSRect(x: 40, y: 38, width: 340, height: 38)
        desc.alignment = .center
        contentView.addSubview(desc)
    }
}

// Simple drawn disk icon
private class DiskIconView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let gray = NSColor(white: 0.35, alpha: 1)
        let lightGray = NSColor(white: 0.55, alpha: 1)

        // Disk body
        let diskPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 8), xRadius: 6, yRadius: 6)
        gray.setFill()
        diskPath.fill()

        // Disk label area
        let labelRect = NSRect(x: 14, y: 20, width: bounds.width - 28, height: bounds.height - 36)
        let labelPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor(white: 0.55, alpha: 1).setFill()
        labelPath.fill()

        // Read head arm
        let armPath = NSBezierPath()
        armPath.move(to: NSPoint(x: bounds.midX - 10, y: 28))
        armPath.line(to: NSPoint(x: bounds.midX + 20, y: 48))
        armPath.lineWidth = 3
        lightGray.setStroke()
        armPath.stroke()

        // LED dot on arm
        let ledRect = NSRect(x: bounds.midX + 16, y: 44, width: 8, height: 8)
        let ledPath = NSBezierPath(ovalIn: ledRect)
        NSColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1).setFill()
        ledPath.fill()
    }
}
