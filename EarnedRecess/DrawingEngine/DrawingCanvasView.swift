import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let template: LetterTemplate
    var phase: Int = 1
    var isEnabled: Bool = true
    var onStrokeAdded: (() -> Void)? = nil

    private var backgroundImage: UIImage? {
        switch phase {
        case 1: return template.templateImage
        case 2: return LetterTemplateLibrary.renderDottedTemplateImage(
                    letter: template.letter,
                    size: LetterTemplate.referenceSize)
        default: return nil
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
        templateImageView.tag = 999
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

        if let imageView = canvas.viewWithTag(999) as? UIImageView {
            imageView.image = backgroundImage
        }
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
