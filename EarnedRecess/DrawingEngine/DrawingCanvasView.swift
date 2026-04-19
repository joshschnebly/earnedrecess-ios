import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let template: LetterTemplate
    var isEnabled: Bool = true
    var onStrokeAdded: (() -> Void)? = nil

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

        // Letter template as background image layer (behind canvas)
        let templateImageView = UIImageView(image: template.templateImage)
        templateImageView.contentMode = .scaleAspectFit
        templateImageView.alpha = 0.25
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

        // Sync drawing if externally cleared
        if canvas.drawing.strokes.count != drawing.strokes.count {
            canvas.drawing = drawing
        }

        // Update template image if letter changed
        if let imageView = canvas.viewWithTag(999) as? UIImageView {
            imageView.image = template.templateImage
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
