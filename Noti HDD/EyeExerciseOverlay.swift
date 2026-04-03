import Cocoa

// MARK: - Debug Logger

// File logging is temporarily disabled, but the implementation is kept here
// commented out so it can be restored easily later.
/*
private let debugLogURL: URL = {
    let fileManager = FileManager.default
    let candidates = [
        Bundle.main.bundleURL.deletingLastPathComponent(),
        URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true),
        fileManager.temporaryDirectory,
    ]

    for directory in candidates where fileManager.isWritableFile(atPath: directory.path) {
        return directory.appendingPathComponent("debug.log")
    }

    return fileManager.temporaryDirectory.appendingPathComponent("debug.log")
}()
*/

func dlog(_ msg: String) {
    let line = "\(Date()) \(msg)\n"
    print(line, terminator: "")
    /*
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: debugLogURL.path),
           let fh = try? FileHandle(forWritingTo: debugLogURL) {
            fh.seekToEndOfFile(); fh.write(data); try? fh.close()
        } else {
            try? data.write(to: debugLogURL)
        }
    }
    */
}

// MARK: - Overlay Window

enum PauseTrigger {
    case circular
    case shake
}

class EyeExerciseOverlayWindow: NSWindow {
    var onDismiss: (() -> Void)?

    private var hamsterView: NSView?
    private var seedViews: [Int: NSView] = [:]   // corner index → seed view
    private var moveTimer: Timer?

    // Animation state
    private var corners: [NSPoint] = []
    private var currentCorner = 0
    private var clockwise = true
    private var isPaused = false

    private var pauseLabel: NSTextField?

    private let size:    CGFloat          // 햄스터 크기 (EyeExerciseManager.hamsterSize)
    private let seedW:   CGFloat = 45    // 해바라기씨 너비
    private let seedH:   CGFloat = 62    // 해바라기씨 높이
    private let padding: CGFloat = 24    // 화면 끝 여백

    init(screen: NSScreen, animates: Bool) {
        size = EyeExerciseManager.shared.hamsterSize
        super.init(contentRect: screen.frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        level = .screenSaver
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        guard let cv = contentView else { return }

        if animates {
            buildCorners(in: cv)
            let style = EyeExerciseManager.shared.hamsterStyle
            if style == "photo", let img = NSImage(named: "hamster_photo") {
                let iv = NSImageView(frame: NSRect(x: corners[0].x, y: corners[0].y,
                                                  width: size, height: size))
                iv.image = img
                iv.imageScaling = .scaleProportionallyUpOrDown
                iv.wantsLayer = true
                cv.addSubview(iv)
                hamsterView = iv
            } else {
                let h = HamsterView(frame: NSRect(x: corners[0].x, y: corners[0].y,
                                                 width: size, height: size))
                h.wantsLayer = true
                cv.addSubview(h)
                hamsterView = h
            }
        }

        addHint(to: cv)
    }

    override var canBecomeKey: Bool { true }

    // MARK: - Layout

    private func buildCorners(in cv: NSView) {
        let w = cv.bounds.width
        let h = cv.bounds.height
        corners = [
            NSPoint(x: padding,            y: h - padding - size), // 0: 좌상
            NSPoint(x: w - padding - size, y: h - padding - size), // 1: 우상
            NSPoint(x: w - padding - size, y: padding),            // 2: 우하
            NSPoint(x: padding,            y: padding),            // 3: 좌하
        ]
    }

    private func addHint(to cv: NSView) {
        let label = NSTextField(labelWithString: "ESC 키를 눌러 종료")
        label.font = NSFont.systemFont(ofSize: 16, weight: .ultraLight)
        label.textColor = NSColor(white: 1, alpha: 0.20)
        label.sizeToFit()
        label.setFrameOrigin(NSPoint(
            x: (cv.bounds.width  - label.bounds.width)  / 2,
            y: 44
        ))
        cv.addSubview(label)
    }

    // MARK: - Seed Management

    private func makeSeedView(frame: NSRect) -> NSView {
        if let img = NSImage(named: "sunflower_seed") {
            let iv = NSImageView(frame: frame)
            iv.image = img
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.wantsLayer = true
            return iv
        } else {
            return SunflowerSeedView(frame: frame)
        }
    }

    /// 특정 코너에 해바라기씨 배치 (delay 초 후, fade-in)
    private func placeSeed(at corner: Int, delay: TimeInterval = 0) {
        guard !corners.isEmpty, seedViews[corner] == nil else { return }
        let cx = corners[corner].x + (size - seedW) / 2
        let cy = corners[corner].y + (size - seedH) / 2
        let seed = makeSeedView(frame: NSRect(x: cx, y: cy, width: seedW, height: seedH))
        seed.wantsLayer = true
        seed.alphaValue = 0

        guard let cv = contentView else { return }
        if let ham = hamsterView {
            cv.addSubview(seed, positioned: .below, relativeTo: ham)
        } else {
            cv.addSubview(seed)
        }
        seedViews[corner] = seed

        let show = { [weak seed] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.40
                seed?.animator().alphaValue = 1.0
            }
        }
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard self != nil else { return }
                show()
            }
        } else {
            show()
        }
    }

    /// 특정 코너의 해바라기씨 제거 (fade-out)
    private func removeSeed(at corner: Int) {
        guard let seed = seedViews[corner] else { return }
        seedViews.removeValue(forKey: corner)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            seed.animator().alphaValue = 0
        }, completionHandler: {
            seed.removeFromSuperview()
        })
    }

    /// 다음 목표 코너에 씨앗 1개 배치
    private func placeSeedForNextTarget() {
        let mode = EyeExerciseManager.shared.movementMode
        let target: Int
        if mode == "random" {
            let available = (0..<4).filter { $0 != currentCorner }
            target = available.randomElement() ?? (currentCorner + 1) % 4
        } else {
            target = clockwise ? (currentCorner + 1) % 4 : (currentCorner - 1 + 4) % 4
        }
        placeSeed(at: target)
    }

    // MARK: - Animation

    func startAnimation() {
        guard let ham = hamsterView, !corners.isEmpty else { return }
        ham.setFrameOrigin(corners[0])
        currentCorner = 0
        clockwise = true
        isPaused = false

        seedViews.values.forEach { $0.removeFromSuperview() }
        seedViews.removeAll()

        placeSeedForNextTarget()
        scheduleMoveAfterPause()
    }

    private var moveDuration: TimeInterval {
        let s = Double(EyeExerciseManager.shared.speed)
        return max(0.35, 3.0 - (s - 1.0) * 0.295)
    }
    private var pauseDuration: TimeInterval {
        let s = Double(EyeExerciseManager.shared.speed)
        return max(0.20, 1.5 - (s - 1.0) * 0.144)
    }

    private func scheduleMoveAfterPause() {
        moveTimer = Timer.scheduledTimer(withTimeInterval: pauseDuration, repeats: false) { [weak self] _ in
            self?.moveToNext()
        }
        RunLoop.main.add(moveTimer!, forMode: .common)
    }

    private func moveToNext() {
        guard let ham = hamsterView else { return }

        // 씨앗이 없으면 다시 배치 후 대기
        guard let target = seedViews.keys.first else {
            placeSeedForNextTarget()
            scheduleMoveAfterPause()
            return
        }

        let prev = currentCorner
        let mode = EyeExerciseManager.shared.movementMode

        // Default 모드: 코너 0 도달 시 방향 반전
        if mode == "default" {
            if clockwise && target == 0 { clockwise = false }
            else if !clockwise && target == 0 { clockwise = true }
        }

        currentCorner = target

        if let drawnHam = ham as? HamsterView {
            drawnHam.movingRight = corners[currentCorner].x > corners[prev].x
            drawnHam.needsDisplay = true
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = moveDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            ctx.allowsImplicitAnimation = true
            ham.animator().setFrameOrigin(corners[currentCorner])
        }, completionHandler: {
            // 씨앗 먹기 → 다음 씨앗 출현
            self.removeSeed(at: self.currentCorner)
            self.placeSeedForNextTarget()
            guard !self.isPaused else { return }   // pause 중이면 다음 이동 예약 안 함
            self.scheduleMoveAfterPause()
        })
    }

    // MARK: - Pause / Resume

    func pauseAnimation(trigger: PauseTrigger) {
        guard !isPaused else { return }
        isPaused = true
        moveTimer?.invalidate()
        moveTimer = nil
        // 진행 중인 이동 애니메이션 즉시 중단
        if let layer = hamsterView?.layer {
            let currentPos = layer.presentation()?.frame.origin ?? hamsterView!.frame.origin
            layer.removeAllAnimations()
            hamsterView?.setFrameOrigin(currentPos)
        }
        showPauseIndicator(trigger: trigger)
    }

    func resumeAnimation() {
        guard isPaused else { return }
        isPaused = false
        hidePauseIndicator()
        scheduleMoveAfterPause()
    }

    private func showPauseIndicator(trigger: PauseTrigger) {
        guard let cv = contentView, pauseLabel == nil else { return }
        let triggerDesc: String
        switch trigger {
        case .circular: triggerDesc = "🔄  원형 동작 감지"
        case .shake:    triggerDesc = "↔︎  흔들기 감지"
        }
        let lbl = NSTextField(labelWithString: "⏸  PAUSE\n\(triggerDesc)\n키보드를 누르면 재개")
        lbl.font                 = NSFont.systemFont(ofSize: 22, weight: .thin)
        lbl.textColor            = NSColor(white: 1, alpha: 0.75)
        lbl.alignment            = .center
        lbl.lineBreakMode        = .byWordWrapping
        lbl.maximumNumberOfLines = 3
        lbl.sizeToFit()
        lbl.setFrameOrigin(NSPoint(
            x: (cv.bounds.width  - lbl.frame.width)  / 2,
            y: (cv.bounds.height - lbl.frame.height) / 2
        ))
        cv.addSubview(lbl)
        pauseLabel = lbl
    }

    private func hidePauseIndicator() {
        pauseLabel?.removeFromSuperview()
        pauseLabel = nil
    }

    // MARK: - Cleanup

    func closeOverlay() {
        moveTimer?.invalidate()
        moveTimer = nil
        seedViews.values.forEach { $0.removeFromSuperview() }
        seedViews.removeAll()
        orderOut(nil)
    }

    override func close() { closeOverlay(); super.close() }
}

// MARK: - Sunflower Seed View (해바라기씨)

class SunflowerSeedView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let w = bounds.width
        let h = bounds.height

        // 위아래 뾰족한 씨앗 모양
        let seedPath = NSBezierPath()
        seedPath.move(to:  NSPoint(x: w * 0.50, y: h * 0.02))          // 아래 끝
        seedPath.curve(to: NSPoint(x: w * 0.50, y: h * 0.98),          // 위 끝
                       controlPoint1: NSPoint(x: -w * 0.10, y: h * 0.28),
                       controlPoint2: NSPoint(x: -w * 0.10, y: h * 0.72))
        seedPath.curve(to: NSPoint(x: w * 0.50, y: h * 0.02),
                       controlPoint1: NSPoint(x:  w * 1.10, y: h * 0.72),
                       controlPoint2: NSPoint(x:  w * 1.10, y: h * 0.28))
        seedPath.close()

        // 황금빛 글로우
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor  = NSColor(red: 0.95, green: 0.78, blue: 0.10, alpha: 0.80)
        glow.shadowBlurRadius = 18
        glow.shadowOffset = .zero
        glow.set()
        NSColor(red: 0.14, green: 0.12, blue: 0.09, alpha: 1).setFill()
        seedPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        // 씨앗 본체 (진한 회갈색)
        NSColor(red: 0.14, green: 0.12, blue: 0.09, alpha: 1).setFill()
        seedPath.fill()

        // 줄무늬 + 반짝임 (씨앗 모양으로 클립)
        NSGraphicsContext.saveGraphicsState()
        seedPath.setClip()

        NSColor(red: 0.50, green: 0.45, blue: 0.36, alpha: 0.65).setStroke()
        for i in 1...3 {
            let x = w * CGFloat(i) / 4.0
            let s = NSBezierPath()
            s.move(to:  NSPoint(x: x, y: 0))
            s.line(to:  NSPoint(x: x, y: h))
            s.lineWidth = 1.2
            s.stroke()
        }

        // 하이라이트 (위쪽 좌측)
        NSColor(white: 1, alpha: 0.16).setFill()
        NSBezierPath(ovalIn: NSRect(x: w * 0.18, y: h * 0.58,
                                    width: w * 0.30, height: h * 0.22)).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

// MARK: - Hamster View

class HamsterView: NSView {
    var movingRight: Bool = true

    private let bodyCol  = NSColor(red: 0.87, green: 0.67, blue: 0.37, alpha: 1)
    private let creamCol = NSColor(red: 0.98, green: 0.89, blue: 0.73, alpha: 1)
    private let pinkCol  = NSColor(red: 1.00, green: 0.70, blue: 0.78, alpha: 1)
    private let noseCol  = NSColor(red: 0.95, green: 0.42, blue: 0.58, alpha: 1)
    private let darkCol  = NSColor(red: 0.10, green: 0.06, blue: 0.06, alpha: 1)

    override func draw(_ dirtyRect: NSRect) {
        let s = bounds.width

        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = NSColor(red: 1, green: 0.78, blue: 0.4, alpha: 0.55)
        glow.shadowBlurRadius = 18
        glow.shadowOffset = .zero
        glow.set()

        for side: CGFloat in [-1, 1] {
            let fx = s * 0.5 + side * s * 0.17
            bodyCol.setFill()
            NSBezierPath(roundedRect: NSRect(x: fx - s*0.10, y: s*0.03,
                                             width: s*0.20, height: s*0.13),
                         xRadius: s*0.06, yRadius: s*0.06).fill()
        }

        let bodyPath = NSBezierPath(roundedRect:
            NSRect(x: s*0.18, y: s*0.10, width: s*0.64, height: s*0.42),
            xRadius: s*0.20, yRadius: s*0.20)
        bodyCol.setFill()
        bodyPath.fill()

        creamCol.setFill()
        NSBezierPath(ovalIn: NSRect(x: s*0.32, y: s*0.12, width: s*0.36, height: s*0.32)).fill()

        for side: CGFloat in [-1, 1] {
            let px = s * 0.5 + side * s * 0.30
            bodyCol.setFill()
            NSBezierPath(roundedRect: NSRect(x: px - s*0.09, y: s*0.08,
                                             width: s*0.18, height: s*0.12),
                         xRadius: s*0.06, yRadius: s*0.06).fill()
        }
        NSGraphicsContext.restoreGraphicsState()

        for side: CGFloat in [-1, 1] {
            let ex = s * 0.5 + side * s * 0.20
            let ey = s * 0.80
            bodyCol.setFill()
            NSBezierPath(ovalIn: NSRect(x: ex-s*0.12, y: ey-s*0.10,
                                        width: s*0.24, height: s*0.22)).fill()
            pinkCol.setFill()
            NSBezierPath(ovalIn: NSRect(x: ex-s*0.07, y: ey-s*0.06,
                                        width: s*0.14, height: s*0.13)).fill()
        }

        bodyCol.setFill()
        NSBezierPath(ovalIn: NSRect(x: s*0.10, y: s*0.40, width: s*0.80, height: s*0.56)).fill()

        creamCol.setFill()
        NSBezierPath(ovalIn: NSRect(x: s*0.02, y: s*0.46, width: s*0.30, height: s*0.28)).fill()
        NSBezierPath(ovalIn: NSRect(x: s*0.68, y: s*0.46, width: s*0.30, height: s*0.28)).fill()

        let eyeOffX: CGFloat = movingRight ? s*0.04 : -s*0.04
        for side: CGFloat in [-1, 1] {
            let ex = s * 0.5 + side * s * 0.16 + eyeOffX
            let ey = s * 0.70
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: ex-s*0.075, y: ey-s*0.075,
                                        width: s*0.15, height: s*0.15)).fill()
            darkCol.setFill()
            NSBezierPath(ovalIn: NSRect(x: ex-s*0.05, y: ey-s*0.05,
                                        width: s*0.10, height: s*0.10)).fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: ex+s*0.01, y: ey+s*0.02,
                                        width: s*0.03, height: s*0.03)).fill()
        }

        noseCol.setFill()
        let nosePath = NSBezierPath()
        nosePath.move(to:  NSPoint(x: s*0.50, y: s*0.62))
        nosePath.line(to:  NSPoint(x: s*0.44, y: s*0.58))
        nosePath.line(to:  NSPoint(x: s*0.56, y: s*0.58))
        nosePath.close()
        nosePath.fill()

        let mouthPath = NSBezierPath()
        mouthPath.move(to:         NSPoint(x: s*0.43, y: s*0.57))
        mouthPath.curve(to:        NSPoint(x: s*0.50, y: s*0.53),
                        controlPoint1: NSPoint(x: s*0.44, y: s*0.54),
                        controlPoint2: NSPoint(x: s*0.48, y: s*0.53))
        mouthPath.curve(to:        NSPoint(x: s*0.57, y: s*0.57),
                        controlPoint1: NSPoint(x: s*0.52, y: s*0.53),
                        controlPoint2: NSPoint(x: s*0.56, y: s*0.54))
        mouthPath.lineWidth = 1.4
        NSColor(red: 0.72, green: 0.38, blue: 0.42, alpha: 1).setStroke()
        mouthPath.stroke()

        let wColor = NSColor(white: 0.9, alpha: 0.65)
        wColor.setStroke()
        for i in 0..<3 {
            let yOff = CGFloat(i) * s * 0.035
            let lw = NSBezierPath()
            lw.move(to:  NSPoint(x: s*0.44, y: s*0.600 - yOff))
            lw.line(to:  NSPoint(x: s*0.18, y: s*0.585 - yOff))
            lw.lineWidth = 0.8; lw.stroke()
            let rw = NSBezierPath()
            rw.move(to:  NSPoint(x: s*0.56, y: s*0.600 - yOff))
            rw.line(to:  NSPoint(x: s*0.82, y: s*0.585 - yOff))
            rw.lineWidth = 0.8; rw.stroke()
        }
    }
}
