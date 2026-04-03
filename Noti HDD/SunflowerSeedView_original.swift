import Cocoa

// MARK: - 원본 SunflowerSeedView (코드로 그린 버전 - 백업)
// 이 파일은 백업용입니다. 현재는 sunflower_seed 이미지 에셋을 사용합니다.

class SunflowerSeedView_Original: NSView {
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
