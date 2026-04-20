import PencilKit
import UIKit

struct StrokeAnalyzer {

    // MARK: - Main scoring entry point

    func score(drawing: PKDrawing,
               template: LetterTemplate,
               canvasSize: CGSize) -> DrawingScore {

        guard !drawing.strokes.isEmpty else { return .zero }

        let overlap     = calculateOverlap(drawing: drawing, template: template, canvasSize: canvasSize)
        let proportion  = calculateProportion(drawing: drawing, template: template, canvasSize: canvasSize)
        let strokeCount = calculateStrokeCount(drawing: drawing, template: template)
        let smoothness  = calculateSmoothness(drawing: drawing)
        let keyPoints   = calculateKeyPointsCoverage(drawing: drawing, template: template, canvasSize: canvasSize)

        let composite = (overlap     * Constants.Scoring.overlapWeight) +
                        (proportion  * Constants.Scoring.proportionWeight) +
                        (strokeCount * Constants.Scoring.strokeCountWeight) +
                        (smoothness  * Constants.Scoring.smoothnessWeight) +
                        (keyPoints   * Constants.Scoring.keyPointsWeight)

        return DrawingScore(
            overlapScore:      overlap,
            proportionScore:   proportion,
            strokeCountScore:  strokeCount,
            smoothnessScore:   smoothness,
            keyPointsScore:    keyPoints,
            compositeScore:    min(1.0, composite)
        )
    }

    // MARK: - Overlap (40%)
    // Rasterize drawing and reference path to bitmaps, count overlapping pixels.

    private func calculateOverlap(drawing: PKDrawing,
                                  template: LetterTemplate,
                                  canvasSize: CGSize) -> Double {
        let bitmapSize = CGSize(width: 200, height: 250)  // reduced for performance
        let scaleX = bitmapSize.width  / canvasSize.width
        let scaleY = bitmapSize.height / canvasSize.height

        // Render the child's drawing
        let drawingImage = drawing.image(from: CGRect(origin: .zero, size: canvasSize),
                                         scale: UIScreen.main.scale)
        guard let drawingBitmap = pixelData(from: drawingImage, size: bitmapSize) else { return 0 }

        // Render the reference path
        let refRenderer = UIGraphicsImageRenderer(size: bitmapSize)
        let refImage = refRenderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(12 * scaleX)
            ctx.cgContext.setLineCap(.round)

            var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            if let scaled = template.referencePath.copy(using: &transform) {
                ctx.cgContext.addPath(scaled)
            }
            ctx.cgContext.strokePath()
        }
        guard let refBitmap = pixelData(from: refImage, size: bitmapSize) else { return 0 }

        // Count reference pixels and overlapping pixels
        var refCount = 0
        var overlapCount = 0
        let total = Int(bitmapSize.width * bitmapSize.height)

        for i in 0..<total {
            let refAlpha  = refBitmap[i * 4 + 3]
            let drawAlpha = drawingBitmap[i * 4 + 3]
            if refAlpha > 50 {
                refCount += 1
                if drawAlpha > 50 { overlapCount += 1 }
            }
        }

        guard refCount > 0 else { return 0 }
        return min(1.0, Double(overlapCount) / Double(refCount))
    }

    // MARK: - Proportion (20%)
    // Compare bounding box aspect ratio of drawn strokes vs expected.

    private func calculateProportion(drawing: PKDrawing,
                                     template: LetterTemplate,
                                     canvasSize: CGSize) -> Double {
        let bounds = drawing.strokes
            .map { $0.renderBounds }
            .reduce(CGRect.null) { $0.union($1) }

        guard bounds != .null, bounds.height > 0 else { return 0 }

        let drawnRatio = bounds.width / bounds.height
        let expectedRatio = template.aspectRatio
        let diff = abs(drawnRatio - expectedRatio) / expectedRatio
        return max(0.0, 1.0 - diff * 1.5)  // 1.5x penalty steepness
    }

    // MARK: - Stroke Count (20%)
    // Penalise extra or missing strokes by 33% each.

    private func calculateStrokeCount(drawing: PKDrawing, template: LetterTemplate) -> Double {
        let actual   = drawing.strokes.count
        let expected = template.expectedStrokeCount
        if actual == expected { return 1.0 }
        let diff = abs(actual - expected)
        return max(0.0, 1.0 - Double(diff) * Constants.Scoring.strokePenaltyPerExtra)
    }

    // MARK: - Smoothness (20%)
    // Measure angular variance between consecutive stroke points.
    // Low variance = smooth lines = high score.

    private func calculateSmoothness(drawing: PKDrawing) -> Double {
        var totalVariance: Double = 0
        var strokeCount = 0

        for stroke in drawing.strokes {
            let points = stroke.path.interpolatedPoints(by: .parametricStep(0.1))
                .map { $0.location }

            guard points.count >= 3 else { continue }

            var angles: [Double] = []
            for i in 1..<points.count {
                let dx = Double(points[i].x - points[i - 1].x)
                let dy = Double(points[i].y - points[i - 1].y)
                if dx != 0 || dy != 0 {
                    angles.append(atan2(dy, dx))
                }
            }

            guard angles.count >= 2 else { continue }

            // Angular difference between consecutive segments
            var diffs: [Double] = []
            for i in 1..<angles.count {
                var diff = abs(angles[i] - angles[i - 1])
                if diff > .pi { diff = 2 * .pi - diff }  // wrap to [0, π]
                diffs.append(diff)
            }

            let mean = diffs.reduce(0, +) / Double(diffs.count)
            totalVariance += mean
            strokeCount += 1
        }

        guard strokeCount > 0 else { return 1.0 }
        let avgVariance = totalVariance / Double(strokeCount)

        // avgVariance near 0 = perfectly smooth, near π = very jagged
        // Map to 0–1 score: variance of 0.3 rad (~17°) scores ~0.7
        return max(0.0, 1.0 - (avgVariance / 0.8))
    }

    // MARK: - Key Points Coverage (15%)
    // For each normalized key point, check if any pixel within toleranceRadius is covered.

    private func calculateKeyPointsCoverage(drawing: PKDrawing,
                                            template: LetterTemplate,
                                            canvasSize: CGSize) -> Double {
        guard !template.keyPoints.isEmpty else { return 1.0 }

        let bitmapSize = CGSize(width: 200, height: 250)
        let drawingImage = drawing.image(from: CGRect(origin: .zero, size: canvasSize),
                                         scale: UIScreen.main.scale)
        guard let drawingBitmap = pixelData(from: drawingImage, size: bitmapSize) else { return 0 }

        let width  = Int(bitmapSize.width)
        let height = Int(bitmapSize.height)
        let radius = Int(Constants.Scoring.keyPointToleranceRadius)
        var hits = 0

        for keyPoint in template.keyPoints {
            let cx = Int(keyPoint.x * bitmapSize.width)
            let cy = Int(keyPoint.y * bitmapSize.height)

            var covered = false
            outer: for dy in -radius...radius {
                for dx in -radius...radius {
                    guard dx * dx + dy * dy <= radius * radius else { continue }
                    let px = cx + dx
                    let py = cy + dy
                    guard px >= 0, px < width, py >= 0, py < height else { continue }
                    let alpha = drawingBitmap[(py * width + px) * 4 + 3]
                    if alpha > 50 { covered = true; break outer }
                }
            }
            if covered { hits += 1 }
        }

        return Double(hits) / Double(template.keyPoints.count)
    }

    // MARK: - Bitmap helper

    private func pixelData(from image: UIImage, size: CGSize) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        let width  = Int(size.width)
        let height = Int(size.height)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return pixels
    }
}
