import UIKit

final class TracingArrowsView: UIView {
    private let strokePaths: [StrokePath]
    private let continuous: Bool
    private let sequential: Bool
    private let strokeDuration: TimeInterval = 1.5
    private var arrowLayers: [CAShapeLayer] = []

    init(strokePaths: [StrokePath], canvasSize: CGSize, continuous: Bool, sequential: Bool) {
        self.strokePaths = strokePaths
        self.continuous = continuous
        self.sequential = sequential
        super.init(frame: CGRect(origin: .zero, size: canvasSize))
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size.width > 0, bounds.size.height > 0, arrowLayers.isEmpty else { return }
        setupAnimations()
    }

    private func arrowHead() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -8))
        path.addLine(to: CGPoint(x: 6, y: 4))
        path.addLine(to: CGPoint(x: -6, y: 4))
        path.close()
        return path
    }

    private func scaledPoints(for stroke: StrokePath) -> [CGPoint] {
        stroke.points.map { CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height) }
    }

    private func keyframeValues(for points: [CGPoint]) -> [CGPoint] {
        guard points.count > 1 else { return points }
        var result: [CGPoint] = []
        for i in 0..<(points.count - 1) {
            let steps = 10
            for s in 0...steps {
                let t = CGFloat(s) / CGFloat(steps)
                let x = points[i].x + (points[i + 1].x - points[i].x) * t
                let y = points[i].y + (points[i + 1].y - points[i].y) * t
                result.append(CGPoint(x: x, y: y))
            }
        }
        return result
    }

    private func rotationValues(for points: [CGPoint]) -> [Double] {
        guard points.count > 1 else { return [0] }
        var result: [Double] = []
        for i in 0..<(points.count - 1) {
            let steps = 10
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let angle = Double(atan2(dy, dx)) + .pi / 2
            for _ in 0...steps {
                result.append(angle)
            }
        }
        return result
    }

    private func makeArrowLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = arrowHead().cgPath
        layer.fillColor = UIColor(named: "erBlue")?.withAlphaComponent(0.6).cgColor
            ?? UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        layer.strokeColor = UIColor.clear.cgColor
        return layer
    }

    private func setupAnimations() {
        if sequential {
            animateSequential(strokeIndex: 0, pass: 0)
        } else {
            for (i, stroke) in strokePaths.enumerated() {
                animateSingle(stroke: stroke, delay: 0, strokeIndex: i, pass: 0)
            }
        }
    }

    private func animateSingle(stroke: StrokePath, delay: TimeInterval, strokeIndex: Int, pass: Int) {
        let points = scaledPoints(for: stroke)
        guard points.count >= 2 else { return }

        let layer = makeArrowLayer()
        let positions = keyframeValues(for: points)
        let rotations = rotationValues(for: points)

        layer.position = positions.first ?? .zero
        self.layer.addSublayer(layer)
        if strokeIndex < arrowLayers.count {
            arrowLayers[strokeIndex] = layer
        } else {
            arrowLayers.append(layer)
        }

        let posAnim = CAKeyframeAnimation(keyPath: "position")
        posAnim.values = positions.map { NSValue(cgPoint: $0) }
        posAnim.duration = strokeDuration
        posAnim.beginTime = CACurrentMediaTime() + delay
        posAnim.calculationMode = .linear
        posAnim.isRemovedOnCompletion = false
        posAnim.fillMode = .forwards

        let rotAnim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotAnim.values = rotations as [NSNumber]
        rotAnim.duration = strokeDuration
        rotAnim.beginTime = CACurrentMediaTime() + delay
        rotAnim.calculationMode = .linear
        rotAnim.isRemovedOnCompletion = false
        rotAnim.fillMode = .forwards

        let group = CAAnimationGroup()
        group.animations = [posAnim, rotAnim]
        group.duration = strokeDuration
        group.beginTime = CACurrentMediaTime() + delay
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        if !continuous {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.duration = 0.4
            fade.beginTime = CACurrentMediaTime() + delay + strokeDuration
            fade.isRemovedOnCompletion = false
            fade.fillMode = .forwards
            layer.add(fade, forKey: "fade_\(strokeIndex)")
        }

        layer.add(group, forKey: "travel_\(strokeIndex)")

        if continuous {
            let totalDuration = strokeDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + totalDuration) { [weak self] in
                guard let self else { return }
                layer.removeFromSuperlayer()
                self.arrowLayers.removeAll { $0 === layer }
                self.animateSingle(stroke: stroke, delay: 0, strokeIndex: strokeIndex, pass: pass + 1)
            }
        }
    }

    private func animateSequential(strokeIndex: Int, pass: Int) {
        guard strokeIndex < strokePaths.count else {
            if continuous {
                animateSequential(strokeIndex: 0, pass: pass + 1)
            }
            return
        }
        let stroke = strokePaths[strokeIndex]
        let layer = makeArrowLayer()
        let points = scaledPoints(for: stroke)
        guard points.count >= 2 else {
            animateSequential(strokeIndex: strokeIndex + 1, pass: pass)
            return
        }
        let positions = keyframeValues(for: points)
        let rotations = rotationValues(for: points)

        layer.position = positions.first ?? .zero
        self.layer.addSublayer(layer)
        arrowLayers.append(layer)

        let posAnim = CAKeyframeAnimation(keyPath: "position")
        posAnim.values = positions.map { NSValue(cgPoint: $0) }
        posAnim.duration = strokeDuration
        posAnim.beginTime = CACurrentMediaTime()
        posAnim.calculationMode = .linear
        posAnim.isRemovedOnCompletion = false
        posAnim.fillMode = .forwards

        let rotAnim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotAnim.values = rotations as [NSNumber]
        rotAnim.duration = strokeDuration
        rotAnim.beginTime = CACurrentMediaTime()
        rotAnim.calculationMode = .linear
        rotAnim.isRemovedOnCompletion = false
        rotAnim.fillMode = .forwards

        let group = CAAnimationGroup()
        group.animations = [posAnim, rotAnim]
        group.duration = strokeDuration
        group.beginTime = CACurrentMediaTime()
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        layer.add(group, forKey: "travel_seq_\(strokeIndex)")

        if !continuous && strokeIndex == strokePaths.count - 1 {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.duration = 0.4
            fade.beginTime = CACurrentMediaTime() + strokeDuration
            fade.isRemovedOnCompletion = false
            fade.fillMode = .forwards
            layer.add(fade, forKey: "fade_seq")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + strokeDuration) { [weak self] in
            guard let self else { return }
            layer.removeFromSuperlayer()
            self.arrowLayers.removeAll { $0 === layer }
            self.animateSequential(strokeIndex: strokeIndex + 1, pass: pass)
        }
    }
}
