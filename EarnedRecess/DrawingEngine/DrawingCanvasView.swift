import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let template: LetterTemplate
    var phase: Int = 1
    var isEnabled: Bool = true
    var showAlignmentLines: Bool = false
    var templateStyle: TemplateStyle = .solid
    var tracingArrowsEnabled: Bool = false
    var tracingArrowsContinuous: Bool = true
    var tracingArrowsSequential: Bool = false
    var onStrokeAdded: (() -> Void)? = nil

    private var effectivePhase: Int {
        switch templateStyle {
        case .dotted: return 2
        case .none: return 3
        default: return phase
        }
    }

    private var backgroundImage: UIImage? {
        switch effectivePhase {
        case 1: return template.templateImage
        case 2: return LetterTemplateLibrary.renderDottedTemplateImage(
                    letter: template.letter,
                    size: LetterTemplate.referenceSize)
        default: return nil
        }
    }

    private func applyAlignmentLines(to canvas: PKCanvasView) {
        canvas.subviews.filter { $0.tag == CanvasViewTag.alignment.rawValue }.forEach { $0.removeFromSuperview() }
        guard showAlignmentLines else { return }
        let lines: [(CGFloat, UIColor)] = [
            (0.15, UIColor(Color.erBlue).withAlphaComponent(0.20)),
            (0.50, UIColor(Color.erBlue).withAlphaComponent(0.30)),
            (0.75, UIColor(Color.erBlue).withAlphaComponent(0.40)),
            (0.90, UIColor(Color.erBlue).withAlphaComponent(0.20)),
        ]
        for (fraction, color) in lines {
            let line = UIView()
            line.tag = CanvasViewTag.alignment.rawValue
            line.backgroundColor = color
            line.translatesAutoresizingMaskIntoConstraints = false
            canvas.insertSubview(line, at: 0)
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
                line.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
                line.heightAnchor.constraint(equalToConstant: 1),
                line.topAnchor.constraint(equalTo: canvas.topAnchor,
                                          constant: canvas.bounds.height * fraction),
            ])
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 8)
        canvas.delegate = context.coordinator

        let templateImageView = UIImageView(image: backgroundImage)
        templateImageView.contentMode = .scaleAspectFit
        templateImageView.alpha = 1.0
        templateImageView.translatesAutoresizingMaskIntoConstraints = false
        templateImageView.tag = CanvasViewTag.template.rawValue
        canvas.insertSubview(templateImageView, at: 0)
        NSLayoutConstraint.activate([
            templateImageView.leadingAnchor.constraint(equalTo: canvas.leadingAnchor, constant: 40),
            templateImageView.trailingAnchor.constraint(equalTo: canvas.trailingAnchor, constant: -40),
            templateImageView.topAnchor.constraint(equalTo: canvas.topAnchor, constant: 40),
            templateImageView.bottomAnchor.constraint(equalTo: canvas.bottomAnchor, constant: -40),
        ])

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEnabled

        if canvas.drawing.strokes.count != drawing.strokes.count {
            canvas.drawing = drawing
        }

        if let imageView = canvas.viewWithTag(CanvasViewTag.template.rawValue) as? UIImageView {
            imageView.image = backgroundImage
        }

        applyAlignmentLines(to: canvas)
        applyTracingArrows(to: canvas)
    }

    private func applyTracingArrows(to canvas: PKCanvasView) {
        canvas.subviews.filter { $0.tag == CanvasViewTag.arrows.rawValue }.forEach { $0.removeFromSuperview() }
        guard tracingArrowsEnabled else { return }
        let strokes = StrokePathLibrary.strokes(for: template.letter)
        guard !strokes.isEmpty else { return }
        let arrowsView = TracingArrowsView(
            strokePaths: strokes,
            canvasSize: canvas.bounds.size,
            continuous: tracingArrowsContinuous,
            sequential: tracingArrowsSequential
        )
        arrowsView.tag = CanvasViewTag.arrows.rawValue
        arrowsView.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(arrowsView)
        NSLayoutConstraint.activate([
            arrowsView.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            arrowsView.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            arrowsView.topAnchor.constraint(equalTo: canvas.topAnchor),
            arrowsView.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
        ])
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onStrokeAdded?()
        }
    }
}

// MARK: - Clear helper

extension PKDrawing {
    static var empty: PKDrawing { PKDrawing() }
}
