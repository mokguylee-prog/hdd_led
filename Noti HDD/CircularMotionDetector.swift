import Cocoa

/// 마우스 원형 동작 감지기
/// 조건: 반지름 > 60px, 변동계수 < 55%, 누적 회전각 ≥ 300°
class CircularMotionDetector {
    var onDetected: (() -> Void)?

    private var points: [NSPoint] = []

    func feed(_ pt: NSPoint) {
        points.append(pt)
        if points.count > 120 { points.removeFirst(points.count - 120) }
        guard points.count >= 40 else { return }
        check()
    }

    func reset() {
        points.removeAll()
        debugCount = 0
    }

    private var debugCount = 0
    private func check() {
        let pts = points
        let n   = CGFloat(pts.count)

        let cx = pts.map(\.x).reduce(0, +) / n
        let cy = pts.map(\.y).reduce(0, +) / n

        let radii = pts.map { hypot($0.x - cx, $0.y - cy) }
        let avgR  = radii.reduce(0, +) / n

        let stdR = sqrt(radii.map { pow($0 - avgR, 2) }.reduce(0, +) / n)
        let cv   = stdR / avgR

        var totalAngle: CGFloat = 0
        for i in 1..<pts.count {
            var diff = atan2(pts[i].y - cy, pts[i].x - cx)
                     - atan2(pts[i-1].y - cy, pts[i-1].x - cx)
            if diff >  .pi { diff -= 2 * .pi }
            if diff < -.pi { diff += 2 * .pi }
            totalAngle += diff
        }
        let deg = abs(totalAngle) * 180 / .pi

        debugCount += 1
        if debugCount % 10 == 0 {
            dlog("[Circle] pts=\(pts.count) avgR=\(Int(avgR)) CV=\(String(format:"%.2f",cv)) angle=\(Int(deg))°")
        }

        guard avgR > 60  else { return }
        guard cv   < 0.55 else { return }
        guard deg  >= 300  else { return }

        dlog("[Circle] ✅ DETECTED")
        points.removeAll()
        DispatchQueue.main.async { self.onDetected?() }
    }
}
