import Foundation

enum EyeExerciseMotion {
    static let defaultSpeed = 3
    static let speedRange = 1...10
    static let pauseDuration: TimeInterval = 1
    static let minimumMovementDuration: TimeInterval = 0.1

    // Preserve the slower levels while providing finer choices for fast movement.
    private static let crossingDurations: [TimeInterval] = [
        18, 9, 6, 4, 2.5, 1.5, 0.8, 0.4, 0.2, 0.1
    ]

    static func clampedSpeed(_ speed: Int) -> Int {
        min(speedRange.upperBound, max(speedRange.lowerBound, speed))
    }

    // A design default inspired by slow tracking guidance, rather than a clinical prescription.
    // https://chopib.staywellsolutionsonline.com/Library/Encyclopedia/22%2C36023
    static func crossingDuration(speed: Int) -> TimeInterval {
        crossingDurations[clampedSpeed(speed) - speedRange.lowerBound]
    }

    static func movementDuration(distance: Double, referenceDistance: Double,
                                 speed: Int) -> TimeInterval {
        let fraction = max(0, distance) / max(1, referenceDistance)
        return max(minimumMovementDuration, crossingDuration(speed: speed) * fraction)
    }
}
