import Foundation

enum EyeExerciseMotion {
    static let defaultSpeed = 3
    static let speedRange = 1...10
    static let pauseDuration: TimeInterval = 1

    static func clampedSpeed(_ speed: Int) -> Int {
        min(speedRange.upperBound, max(speedRange.lowerBound, speed))
    }

    // A design default inspired by slow tracking guidance, rather than a clinical prescription.
    // https://chopib.staywellsolutionsonline.com/Library/Encyclopedia/22%2C36023
    static func crossingDuration(speed: Int) -> TimeInterval {
        18 / Double(clampedSpeed(speed))
    }

    static func movementDuration(distance: Double, referenceDistance: Double,
                                 speed: Int) -> TimeInterval {
        let fraction = max(0, distance) / max(1, referenceDistance)
        return max(0.15, crossingDuration(speed: speed) * fraction)
    }
}
