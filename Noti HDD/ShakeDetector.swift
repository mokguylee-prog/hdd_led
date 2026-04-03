import Cocoa

/// 시간 기반 마우스 흔들기 감지기
/// 조건: 1.5초 이내 빠른 축 반전 3회 이상
class ShakeDetector {
    var onDetected: (() -> Void)?

    private struct Sample {
        let point: NSPoint
        let time: TimeInterval
    }

    private var lastSample: Sample?
    private var previousVelocity: CGVector = .zero
    private var reversals: [TimeInterval] = []
    private var lastResetLogAt: TimeInterval = 0

    private let reversalWindow: TimeInterval = 1.5
    private let staleSampleWindow: TimeInterval = 0.35
    private let minimumDistance: CGFloat = 2
    private let minimumSpeed: CGFloat = 220
    private let reversalCosineThreshold: CGFloat = -0.2

    func reset() {
        lastSample = Sample(point: NSEvent.mouseLocation, time: ProcessInfo.processInfo.systemUptime)
        lastResetLogAt = 0
        clearMotionState()
    }

    func feed(_ pt: NSPoint) {
        let now = ProcessInfo.processInfo.systemUptime
        guard let lastSample else {
            self.lastSample = Sample(point: pt, time: now)
            return
        }

        let dt = now - lastSample.time
        self.lastSample = Sample(point: pt, time: now)

        guard dt > 0 else { return }

        if dt > staleSampleWindow {
            logResetIfNeeded(now: now, reason: String(format: "stale dt=%.3f", dt))
            clearMotionState()
        }

        let dx = pt.x - lastSample.point.x
        let dy = pt.y - lastSample.point.y
        let distance = hypot(dx, dy)

        guard distance >= minimumDistance else { return }

        let vx = dx / dt
        let vy = dy / dt
        let speed = hypot(vx, vy)

        guard speed >= minimumSpeed else {
            if !reversals.isEmpty {
                logResetIfNeeded(now: now, reason: "slow speed=\(Int(speed))")
            }
            return
        }

        let velocity = CGVector(dx: vx, dy: vy)
        let prevSpeed = hypot(previousVelocity.dx, previousVelocity.dy)

        if prevSpeed >= minimumSpeed {
            let dot = velocity.dx * previousVelocity.dx + velocity.dy * previousVelocity.dy
            let cosine = dot / (speed * prevSpeed)

            if cosine <= reversalCosineThreshold {
                reversals.append(now)
                pruneReversals(now: now)
                dlog("[Shake] reversal #\(reversals.count) speed=\(Int(speed)) cosine=\(String(format: "%.2f", cosine))")

                if reversals.count >= 3 {
                    dlog("[Shake] ✅ DETECTED")
                    clearMotionState()
                    DispatchQueue.main.async { self.onDetected?() }
                    return
                }
            }
        }

        previousVelocity = velocity
        pruneReversals(now: now)
    }

    private func pruneReversals(now: TimeInterval) {
        reversals = reversals.filter { now - $0 < reversalWindow }
    }

    private func clearMotionState() {
        previousVelocity = .zero
        reversals.removeAll()
    }

    private func logResetIfNeeded(now: TimeInterval, reason: String) {
        guard now - lastResetLogAt >= 0.15 else { return }
        guard !reversals.isEmpty || hypot(previousVelocity.dx, previousVelocity.dy) >= minimumSpeed else { return }
        lastResetLogAt = now
        dlog("[Shake] reset \(reason)")
    }
}
