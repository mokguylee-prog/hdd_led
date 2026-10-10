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

    private var rocketView: RocketView?
    private var targetViews: [Int: NSView] = [:]   // corner index → target marker
    private var moveTimer: Timer?

    // Animation state
    private var corners: [NSPoint] = []
    private var currentCorner = 0
    private var clockwise = true
    private var isPaused = false
    private var isClosed = false
    private var animationGeneration = 0

    private var pauseLabel: NSTextField?

    private let size:    CGFloat          // 로켓 크기 (EyeExerciseManager.rocketSize)
    private let targetDiameter: CGFloat = 8
    private let padding: CGFloat = 24    // 화면 끝 여백

    init(screen: NSScreen, animates: Bool) {
        size = EyeExerciseManager.shared.rocketSize
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
            let rocket = RocketView(frame: NSRect(x: corners[0].x, y: corners[0].y,
                                                  width: size, height: size))
            rocket.wantsLayer = true
            rocket.setAccessibilityRole(.image)
            rocket.setAccessibilityLabel("눈운동 나로호 로켓")
            cv.addSubview(rocket)
            rocketView = rocket
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

    // MARK: - Target Markers

    /// 다음 이동 위치를 작은 점으로 표시합니다.
    private func placeTarget(at corner: Int) {
        guard !corners.isEmpty, targetViews[corner] == nil,
              let cv = contentView else { return }
        let marker = NSView(frame: NSRect(
            x: corners[corner].x + (size - targetDiameter) / 2,
            y: corners[corner].y + (size - targetDiameter) / 2,
            width: targetDiameter, height: targetDiameter
        ))
        marker.wantsLayer = true
        marker.layer?.cornerRadius = targetDiameter / 2
        marker.layer?.backgroundColor = NSColor(calibratedWhite: 0.75, alpha: 1).cgColor
        marker.alphaValue = 0
        cv.addSubview(marker, positioned: .below, relativeTo: rocketView)
        targetViews[corner] = marker
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.40
            marker.animator().alphaValue = 1
        }
    }

    private func removeTarget(at corner: Int) {
        guard let marker = targetViews.removeValue(forKey: corner) else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            marker.animator().alphaValue = 0
        }, completionHandler: {
            marker.removeFromSuperview()
        })
    }

    /// 순환 또는 랜덤 모드로 다음 이동 목표를 선택합니다.
    private func placeNextTarget() {
        let mode = EyeExerciseManager.shared.movementMode
        let target: Int
        if mode == "random" {
            let available = (0..<4).filter { $0 != currentCorner }
            target = available.randomElement() ?? (currentCorner + 1) % 4
        } else {
            target = clockwise ? (currentCorner + 1) % 4 : (currentCorner - 1 + 4) % 4
        }
        placeTarget(at: target)
    }

    // MARK: - Animation

    func startAnimation() {
        guard let rocket = rocketView, !corners.isEmpty else { return }
        animationGeneration += 1
        moveTimer?.invalidate()
        rocket.layer?.removeAllAnimations()
        rocket.setFrameOrigin(corners[0])
        rocket.heading = 0
        currentCorner = 0
        clockwise = true
        isPaused = false
        isClosed = false

        targetViews.values.forEach { $0.removeFromSuperview() }
        targetViews.removeAll()

        placeNextTarget()
        scheduleMoveAfterPause()
    }

    private func scheduleMoveAfterPause() {
        guard !isPaused, !isClosed else { return }
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: EyeExerciseMotion.pauseDuration, repeats: false) { [weak self] _ in
            self?.moveToNext()
        }
        RunLoop.main.add(moveTimer!, forMode: .common)
    }

    private func moveToNext() {
        guard !isPaused, !isClosed, let rocket = rocketView else { return }

        // 이동 목표가 없으면 다시 표시 후 대기
        guard let target = targetViews.keys.first else {
            placeNextTarget()
            scheduleMoveAfterPause()
            return
        }

        let origin = rocket.frame.origin
        let destination = corners[target]
        rocket.heading = atan2(destination.y - origin.y, destination.x - origin.x) - .pi / 2
        let distance = hypot(destination.x - origin.x, destination.y - origin.y)
        let referenceDistance = max(abs(corners[1].x - corners[0].x),
                                    abs(corners[3].y - corners[0].y))
        let duration = EyeExerciseMotion.movementDuration(
            distance: Double(distance), referenceDistance: Double(referenceDistance),
            speed: EyeExerciseManager.shared.speed
        )
        animationGeneration += 1
        let generation = animationGeneration

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .linear)
            ctx.allowsImplicitAnimation = true
            rocket.animator().setFrameOrigin(destination)
        }, completionHandler: { [weak self] in
            guard let self, !self.isPaused, !self.isClosed,
                  self.animationGeneration == generation else { return }
            self.currentCorner = target
            if EyeExerciseManager.shared.movementMode == "default", target == 0 {
                self.clockwise.toggle()
            }
            // 도착한 목표를 지우고 다음 이동 위치 표시
            self.removeTarget(at: target)
            self.placeNextTarget()
            self.scheduleMoveAfterPause()
        })
    }

    // MARK: - Pause / Resume

    func pauseAnimation(trigger: PauseTrigger) {
        guard !isPaused, !isClosed else { return }
        isPaused = true
        animationGeneration += 1
        moveTimer?.invalidate()
        moveTimer = nil
        // 진행 중인 이동 애니메이션 즉시 중단
        if let rocket = rocketView, let layer = rocket.layer {
            let currentPos = layer.presentation()?.frame.origin ?? rocket.frame.origin
            layer.removeAllAnimations()
            rocket.setFrameOrigin(currentPos)
        }
        showPauseIndicator(trigger: trigger)
    }

    func resumeAnimation() {
        guard isPaused, !isClosed else { return }
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
        isClosed = true
        animationGeneration += 1
        moveTimer?.invalidate()
        moveTimer = nil
        rocketView?.layer?.removeAllAnimations()
        targetViews.values.forEach { $0.removeFromSuperview() }
        targetViews.removeAll()
        orderOut(nil)
    }

    override func close() { closeOverlay(); super.close() }
}
