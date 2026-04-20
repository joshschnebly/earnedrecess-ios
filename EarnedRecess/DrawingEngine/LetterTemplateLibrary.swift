import UIKit

/// Generates LetterTemplate instances programmatically using Core Graphics.
/// Letter "A" uses a hand-crafted CGPath for best scoring accuracy.
/// All others render from the system font glyph via CTFont.
enum LetterTemplateLibrary {

    // MARK: - Public API

    static func template(for letter: String) -> LetterTemplate {
        switch letter {
        // Uppercase A–Z
        case "A": return makeA()
        case "B": return make("B", strokes: 2, ratio: 0.72, keys: [(0.5,0.05),(0.15,0.95),(0.85,0.95)])
        case "C": return make("C", strokes: 1, ratio: 0.80, keys: [(0.85,0.2),(0.15,0.5),(0.85,0.8)])
        case "D": return make("D", strokes: 2, ratio: 0.72, keys: [(0.2,0.05),(0.2,0.95),(0.8,0.5)])
        case "E": return make("E", strokes: 4, ratio: 0.65, keys: [(0.2,0.05),(0.2,0.95),(0.8,0.5)])
        case "F": return make("F", strokes: 3, ratio: 0.60, keys: [(0.2,0.05),(0.2,0.95),(0.7,0.45)])
        case "G": return make("G", strokes: 1, ratio: 0.82, keys: [(0.85,0.2),(0.15,0.5),(0.85,0.8),(0.85,0.5)])
        case "H": return make("H", strokes: 3, ratio: 0.75, keys: [(0.2,0.05),(0.8,0.05),(0.5,0.5)])
        case "I": return make("I", strokes: 1, ratio: 0.30, keys: [(0.5,0.05),(0.5,0.95)])
        case "J": return make("J", strokes: 1, ratio: 0.45, keys: [(0.65,0.05),(0.65,0.75),(0.35,0.95)])
        case "K": return make("K", strokes: 3, ratio: 0.72, keys: [(0.2,0.05),(0.2,0.95),(0.8,0.05),(0.8,0.95)])
        case "L": return make("L", strokes: 2, ratio: 0.60, keys: [(0.2,0.05),(0.2,0.95),(0.8,0.95)])
        case "M": return make("M", strokes: 4, ratio: 0.90, keys: [(0.1,0.95),(0.1,0.05),(0.5,0.55),(0.9,0.05),(0.9,0.95)])
        case "N": return make("N", strokes: 3, ratio: 0.78, keys: [(0.15,0.95),(0.15,0.05),(0.85,0.95),(0.85,0.05)])
        case "O": return make("O", strokes: 1, ratio: 0.88, keys: [(0.5,0.05),(0.95,0.5),(0.5,0.95),(0.05,0.5)])
        case "P": return make("P", strokes: 2, ratio: 0.65, keys: [(0.2,0.05),(0.2,0.95),(0.8,0.3)])
        case "Q": return make("Q", strokes: 2, ratio: 0.88, keys: [(0.5,0.05),(0.5,0.95),(0.75,0.75)])
        case "R": return make("R", strokes: 3, ratio: 0.68, keys: [(0.2,0.05),(0.2,0.95),(0.75,0.3),(0.8,0.95)])
        case "S": return make("S", strokes: 1, ratio: 0.72, keys: [(0.8,0.2),(0.2,0.4),(0.8,0.6),(0.2,0.8)])
        case "T": return make("T", strokes: 2, ratio: 0.75, keys: [(0.1,0.05),(0.9,0.05),(0.5,0.05),(0.5,0.95)])
        case "U": return make("U", strokes: 1, ratio: 0.75, keys: [(0.2,0.05),(0.2,0.75),(0.5,0.95),(0.8,0.75),(0.8,0.05)])
        case "V": return make("V", strokes: 2, ratio: 0.80, keys: [(0.1,0.05),(0.5,0.95),(0.9,0.05)])
        case "W": return make("W", strokes: 4, ratio: 1.10, keys: [(0.05,0.05),(0.25,0.95),(0.5,0.55),(0.75,0.95),(0.95,0.05)])
        case "X": return make("X", strokes: 2, ratio: 0.80, keys: [(0.1,0.05),(0.9,0.95),(0.9,0.05),(0.1,0.95)])
        case "Y": return make("Y", strokes: 3, ratio: 0.75, keys: [(0.1,0.05),(0.5,0.5),(0.9,0.05),(0.5,0.95)])
        case "Z": return make("Z", strokes: 3, ratio: 0.80, keys: [(0.1,0.05),(0.9,0.05),(0.1,0.95),(0.9,0.95)])

        // Lowercase a–z
        case "a": return make("a", strokes: 1, ratio: 0.85, keys: [(0.8,0.3),(0.5,0.15),(0.2,0.5),(0.5,0.85),(0.8,0.5),(0.8,0.95)])
        case "b": return make("b", strokes: 2, ratio: 0.70, keys: [(0.25,0.05),(0.25,0.95),(0.75,0.55)])
        case "c": return make("c", strokes: 1, ratio: 0.80, keys: [(0.8,0.3),(0.2,0.55),(0.8,0.8)])
        case "d": return make("d", strokes: 2, ratio: 0.70, keys: [(0.75,0.05),(0.75,0.95),(0.25,0.55)])
        case "e": return make("e", strokes: 1, ratio: 0.85, keys: [(0.2,0.55),(0.8,0.55),(0.85,0.35),(0.5,0.15),(0.15,0.55),(0.5,0.9),(0.85,0.75)])
        case "f": return make("f", strokes: 2, ratio: 0.50, keys: [(0.7,0.1),(0.4,0.1),(0.4,0.95),(0.2,0.45),(0.65,0.45)])
        case "g": return make("g", strokes: 2, ratio: 0.80, keys: [(0.8,0.3),(0.5,0.15),(0.2,0.5),(0.5,0.85),(0.8,0.5),(0.8,1.1)])
        case "h": return make("h", strokes: 2, ratio: 0.70, keys: [(0.25,0.05),(0.25,0.95),(0.75,0.5),(0.75,0.95)])
        case "i": return make("i", strokes: 2, ratio: 0.25, keys: [(0.5,0.15),(0.5,0.4),(0.5,0.95)])
        case "j": return make("j", strokes: 2, ratio: 0.30, keys: [(0.6,0.15),(0.6,0.4),(0.6,0.9),(0.3,1.05)])
        case "k": return make("k", strokes: 3, ratio: 0.70, keys: [(0.25,0.05),(0.25,0.95),(0.75,0.4),(0.75,0.95)])
        case "l": return make("l", strokes: 1, ratio: 0.25, keys: [(0.5,0.05),(0.5,0.95)])
        case "m": return make("m", strokes: 3, ratio: 1.10, keys: [(0.1,0.35),(0.1,0.95),(0.5,0.35),(0.5,0.95),(0.9,0.35),(0.9,0.95)])
        case "n": return make("n", strokes: 2, ratio: 0.75, keys: [(0.2,0.35),(0.2,0.95),(0.75,0.45),(0.75,0.95)])
        case "o": return make("o", strokes: 1, ratio: 0.90, keys: [(0.5,0.15),(0.9,0.55),(0.5,0.9),(0.1,0.55)])
        case "p": return make("p", strokes: 2, ratio: 0.70, keys: [(0.25,0.35),(0.25,1.1),(0.75,0.55)])
        case "q": return make("q", strokes: 2, ratio: 0.70, keys: [(0.75,0.35),(0.75,1.1),(0.25,0.55)])
        case "r": return make("r", strokes: 2, ratio: 0.60, keys: [(0.2,0.35),(0.2,0.95),(0.7,0.4)])
        case "s": return make("s", strokes: 1, ratio: 0.72, keys: [(0.75,0.35),(0.25,0.5),(0.75,0.7),(0.25,0.9)])
        case "t": return make("t", strokes: 2, ratio: 0.55, keys: [(0.5,0.05),(0.5,0.95),(0.2,0.4),(0.75,0.4)])
        case "u": return make("u", strokes: 1, ratio: 0.75, keys: [(0.2,0.35),(0.2,0.8),(0.5,0.95),(0.8,0.8),(0.8,0.35),(0.8,0.95)])
        case "v": return make("v", strokes: 2, ratio: 0.80, keys: [(0.1,0.35),(0.5,0.95),(0.9,0.35)])
        case "w": return make("w", strokes: 4, ratio: 1.10, keys: [(0.05,0.35),(0.28,0.9),(0.5,0.6),(0.72,0.9),(0.95,0.35)])
        case "x": return make("x", strokes: 2, ratio: 0.80, keys: [(0.1,0.35),(0.9,0.95),(0.9,0.35),(0.1,0.95)])
        case "y": return make("y", strokes: 2, ratio: 0.75, keys: [(0.1,0.35),(0.5,0.7),(0.9,0.35),(0.5,0.7),(0.3,1.05)])
        case "z": return make("z", strokes: 3, ratio: 0.80, keys: [(0.1,0.35),(0.9,0.35),(0.1,0.95),(0.9,0.95)])

        default:  return make(letter, strokes: 1, ratio: 0.75, keys: [(0.5,0.5)])
        }
    }

    // MARK: - Letter A (hand-crafted reference path)

    private static func makeA() -> LetterTemplate {
        let size = LetterTemplate.referenceSize
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.05))
        path.addLine(to: CGPoint(x: size.width * 0.10, y: size.height * 0.95))
        path.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.05))
        path.addLine(to: CGPoint(x: size.width * 0.90, y: size.height * 0.95))
        path.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.55))
        path.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.55))
        return LetterTemplate(
            letter: "A", isUppercase: true,
            expectedStrokeCount: 3, aspectRatio: 0.80,
            keyPoints: [CGPoint(x:0.50,y:0.05),CGPoint(x:0.10,y:0.95),
                        CGPoint(x:0.90,y:0.95),CGPoint(x:0.50,y:0.55)],
            referencePath: path,
            templateImage: renderTemplateImage(letter: "A", size: size)
        )
    }

    // MARK: - Generic builder

    private static func make(_ letter: String,
                              strokes: Int,
                              ratio: CGFloat,
                              keys: [(Double, Double)]) -> LetterTemplate {
        let size = LetterTemplate.referenceSize
        let isUpper = letter == letter.uppercased()
        let keyPoints = keys.map { CGPoint(x: $0.0, y: $0.1) }
        let path = renderGlyphPath(letter: letter, size: size) ?? CGMutablePath()
        return LetterTemplate(
            letter: letter, isUppercase: isUpper,
            expectedStrokeCount: strokes, aspectRatio: ratio,
            keyPoints: keyPoints,
            referencePath: path,
            templateImage: renderTemplateImage(letter: letter, size: size)
        )
    }

    // MARK: - Core Graphics

    private static func renderTemplateImage(letter: String, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let font = UIFont.systemFont(ofSize: size.height * 0.80, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.systemBlue.withAlphaComponent(0.25)
            ]
            let str = NSAttributedString(string: letter, attributes: attrs)
            let textSize = str.size()
            str.draw(at: CGPoint(x: (size.width - textSize.width) / 2,
                                 y: (size.height - textSize.height) / 2))
        }
    }

    static func renderDottedTemplateImage(letter: String, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            guard let path = renderGlyphPath(letter: letter, size: size) else { return }
            let cgCtx = ctx.cgContext
            cgCtx.addPath(path)
            cgCtx.setLineWidth(6)
            cgCtx.setLineDash(phase: 0, lengths: [12, 8])
            cgCtx.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.45).cgColor)
            cgCtx.strokePath()
        }
    }

    private static func renderGlyphPath(letter: String, size: CGSize) -> CGPath? {
        guard let scalar = letter.unicodeScalars.first else { return nil }
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, size.height * 0.80, nil)
        var chars = [UniChar(scalar.value)]
        var glyphs = [CGGlyph(0)]
        CTFontGetGlyphsForCharacters(font, &chars, &glyphs, 1)
        guard glyphs[0] != 0, let glyphPath = CTFontCreatePathForGlyph(font, glyphs[0], nil) else { return nil }

        let bounds = glyphPath.boundingBox
        let offsetX = (size.width  - bounds.width)  / 2 - bounds.minX
        let offsetY = (size.height - bounds.height) / 2 - bounds.minY
        var transform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: offsetX, y: -(size.height + offsetY - bounds.height))
        return glyphPath.copy(using: &transform)
    }
}
