import Cocoa

class EyeExerciseManager {
    static let shared = EyeExerciseManager()

    var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "eyeExerciseEnabled")
            isEnabled ? startTimer() : stopTimer()
            if !isEnabled { dismissOverlay() }
        }
    }

    var intervalMinutes: Int = 50 {
        didSet {
            let clamped = max(1, min(480, intervalMinutes))
            intervalMinutes = clamped
            UserDefaults.standard.set(clamped, forKey: "eyeExerciseMinutes")
            if isEnabled { startTimer() }
        }
    }

    var speed: Int = EyeExerciseMotion.defaultSpeed {
        didSet {
            let clamped = EyeExerciseMotion.clampedSpeed(speed)
            speed = clamped
            UserDefaults.standard.set(clamped, forKey: "eyeExerciseMovementSpeed")
        }
    }

    // "default" = 시계/반시계 순환, "random" = 랜덤 모서리
    var movementMode: String = "default" {
        didSet {
            UserDefaults.standard.set(movementMode, forKey: "eyeExerciseMovementMode")
        }
    }

    // 로켓 크기 (10~100%, 50% = 50pt)
    var rocketSizePercent: Int = 50 {
        didSet {
            let clamped = max(10, min(100, rocketSizePercent))
            rocketSizePercent = clamped
            UserDefaults.standard.set(clamped, forKey: "eyeExerciseSizePercent")
        }
    }

    var rocketSize: CGFloat { CGFloat(rocketSizePercent) }

    // pause 트리거 활성화 여부
    var circularDetectorEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(circularDetectorEnabled, forKey: "eyeExerciseCircularEnabled")
            detectorSettingsDidChange()
        }
    }
    var shakeDetectorEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(shakeDetectorEnabled, forKey: "eyeExerciseShakeEnabled")
            detectorSettingsDidChange()
        }
    }

    private var timer: Timer?
    private var overlays: [EyeExerciseOverlayWindow] = []
    private var mouseMonitor: Any?
    private var keyMonitor: Any?
    private var overlayPaused = false

    private var circularDetector = CircularMotionDetector()
    private var shakeDetector = ShakeDetector()

    private init() {
        let savedMin = UserDefaults.standard.integer(forKey: "eyeExerciseMinutes")
        intervalMinutes = savedMin > 0 ? savedMin : 50
        // Use the new default when upgrading from the previous timing scale.
        let savedSpeed = UserDefaults.standard.object(forKey: "eyeExerciseMovementSpeed") as? Int
            ?? EyeExerciseMotion.defaultSpeed
        speed = EyeExerciseMotion.clampedSpeed(savedSpeed)
        let savedMode = UserDefaults.standard.string(forKey: "eyeExerciseMovementMode") ?? "default"
        movementMode = savedMode
        let savedSizePercent = UserDefaults.standard.object(forKey: "eyeExerciseSizePercent") as? Int
            ?? 50
        rocketSizePercent = max(10, min(100, savedSizePercent))
        // 저장된 값이 없으면 기본 true (UserDefaults.bool 은 key 없으면 false 반환하므로 object 확인)
        let circ = UserDefaults.standard.object(forKey: "eyeExerciseCircularEnabled") as? Bool ?? true
        circularDetectorEnabled = circ
        let shake = UserDefaults.standard.object(forKey: "eyeExerciseShakeEnabled") as? Bool ?? true
        shakeDetectorEnabled = shake
        isEnabled = UserDefaults.standard.bool(forKey: "eyeExerciseEnabled")
    }

    func startTimer() {
        stopTimer()
        let interval = TimeInterval(intervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.showOverlay() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func showOverlay() {
        dismissOverlay()
        overlayPaused = false
        var first = true
        for screen in NSScreen.screens {
            let w = EyeExerciseOverlayWindow(screen: screen, animates: first)
            w.onDismiss = { [weak self] in self?.dismissOverlay() }
            w.makeKeyAndOrderFront(nil)
            overlays.append(w)
            if first { w.startAnimation(); first = false }
        }
        rebuildDetectors()
        installOverlayInputMonitors()
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismissOverlay() {
        removeOverlayInputMonitors()
        overlayPaused = false
        overlays.forEach { $0.closeOverlay() }
        overlays.removeAll()
        rebuildDetectors()
    }

    private func rebuildDetectors() {
        circularDetector = CircularMotionDetector()
        shakeDetector = ShakeDetector()
        dlog("[Detector] circularEnabled=\(circularDetectorEnabled) shakeEnabled=\(shakeDetectorEnabled)")

        circularDetector.onDetected = circularDetectorEnabled
            ? { [weak self] in self?.pauseOverlays(trigger: .circular) }
            : nil
        shakeDetector.onDetected = shakeDetectorEnabled
            ? { [weak self] in self?.pauseOverlays(trigger: .shake) }
            : nil

        circularDetector.reset()
        shakeDetector.reset()
    }

    private func detectorSettingsDidChange() {
        rebuildDetectors()
    }

    private func installOverlayInputMonitors() {
        removeOverlayInputMonitors()

        mouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] event in
            guard let self else { return event }
            guard !self.overlayPaused else { return event }

            let pt = NSEvent.mouseLocation
            if self.circularDetectorEnabled {
                self.circularDetector.feed(pt)
            }
            if self.shakeDetectorEnabled {
                self.shakeDetector.feed(pt)
            }
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            if event.keyCode == 53 {
                self.dismissOverlay()
                return nil
            }

            if self.overlayPaused {
                self.resumeOverlays()
                return nil
            }

            return event
        }
    }

    private func removeOverlayInputMonitors() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func pauseOverlays(trigger: PauseTrigger) {
        guard !overlayPaused else { return }
        overlayPaused = true
        overlays.forEach { $0.pauseAnimation(trigger: trigger) }
    }

    private func resumeOverlays() {
        guard overlayPaused else { return }
        overlayPaused = false
        circularDetector.reset()
        shakeDetector.reset()
        overlays.forEach { $0.resumeAnimation() }
    }
}
