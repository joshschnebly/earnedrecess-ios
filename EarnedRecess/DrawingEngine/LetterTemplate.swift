import UIKit

struct LetterTemplate {
    let letter: String
    let isUppercase: Bool
    let expectedStrokeCount: Int
    let aspectRatio: CGFloat          // expected width / height
    let keyPoints: [CGPoint]          // normalized 0–1, must-hit points
    let referencePath: CGPath         // for overlap scoring
    let templateImage: UIImage        // semi-transparent overlay shown to child

    // Canonical canvas size used when generating reference paths
    static let referenceSize = CGSize(width: 400, height: 500)
}

// MARK: - Drawing Score

struct DrawingScore {
    let overlapScore: Double
    let proportionScore: Double
    let strokeCountScore: Double
    let smoothnessScore: Double
    let keyPointsScore: Double
    let compositeScore: Double

    /// 1–3 star rating for child display
    var starRating: Int {
        switch compositeScore {
        case 0.80...: return 3
        case 0.60...: return 2
        default: return 1
        }
    }

    var passed: Bool { compositeScore >= 0.60 }

    static var zero: DrawingScore {
        DrawingScore(overlapScore: 0, proportionScore: 0,
                     strokeCountScore: 0, smoothnessScore: 0,
                     keyPointsScore: 0, compositeScore: 0)
    }
}
