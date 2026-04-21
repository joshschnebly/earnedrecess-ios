import CoreGraphics

struct StrokePath {
    let points: [CGPoint]
}

enum StrokePathLibrary {
    static let paths: [String: [StrokePath]] = [
        "A": [
            StrokePath(points: [CGPoint(x: 0.50, y: 0.05), CGPoint(x: 0.10, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.50, y: 0.05), CGPoint(x: 0.90, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.25, y: 0.55), CGPoint(x: 0.75, y: 0.55)]),
        ],
        "B": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [
                CGPoint(x: 0.20, y: 0.05),
                CGPoint(x: 0.75, y: 0.15),
                CGPoint(x: 0.80, y: 0.30),
                CGPoint(x: 0.75, y: 0.45),
                CGPoint(x: 0.20, y: 0.50),
                CGPoint(x: 0.78, y: 0.60),
                CGPoint(x: 0.82, y: 0.75),
                CGPoint(x: 0.78, y: 0.88),
                CGPoint(x: 0.20, y: 0.95),
            ]),
        ],
        "C": [
            StrokePath(points: [
                CGPoint(x: 0.80, y: 0.20),
                CGPoint(x: 0.60, y: 0.05),
                CGPoint(x: 0.35, y: 0.05),
                CGPoint(x: 0.15, y: 0.20),
                CGPoint(x: 0.10, y: 0.50),
                CGPoint(x: 0.15, y: 0.80),
                CGPoint(x: 0.35, y: 0.95),
                CGPoint(x: 0.60, y: 0.95),
                CGPoint(x: 0.80, y: 0.80),
            ]),
        ],
        "D": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [
                CGPoint(x: 0.20, y: 0.05),
                CGPoint(x: 0.65, y: 0.10),
                CGPoint(x: 0.85, y: 0.30),
                CGPoint(x: 0.85, y: 0.70),
                CGPoint(x: 0.65, y: 0.90),
                CGPoint(x: 0.20, y: 0.95),
            ]),
        ],
        "E": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.80, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.70, y: 0.50)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.95), CGPoint(x: 0.80, y: 0.95)]),
        ],
        "F": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.80, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.70, y: 0.50)]),
        ],
        "G": [
            StrokePath(points: [
                CGPoint(x: 0.80, y: 0.20),
                CGPoint(x: 0.60, y: 0.05),
                CGPoint(x: 0.35, y: 0.05),
                CGPoint(x: 0.15, y: 0.20),
                CGPoint(x: 0.10, y: 0.50),
                CGPoint(x: 0.15, y: 0.80),
                CGPoint(x: 0.35, y: 0.95),
                CGPoint(x: 0.60, y: 0.95),
                CGPoint(x: 0.82, y: 0.80),
                CGPoint(x: 0.82, y: 0.55),
                CGPoint(x: 0.55, y: 0.55),
            ]),
        ],
        "H": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.80, y: 0.05), CGPoint(x: 0.80, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.80, y: 0.50)]),
        ],
        "I": [
            StrokePath(points: [CGPoint(x: 0.50, y: 0.05), CGPoint(x: 0.50, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.30, y: 0.05), CGPoint(x: 0.70, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.30, y: 0.95), CGPoint(x: 0.70, y: 0.95)]),
        ],
        "J": [
            StrokePath(points: [CGPoint(x: 0.30, y: 0.05), CGPoint(x: 0.70, y: 0.05)]),
            StrokePath(points: [
                CGPoint(x: 0.55, y: 0.05),
                CGPoint(x: 0.55, y: 0.78),
                CGPoint(x: 0.50, y: 0.90),
                CGPoint(x: 0.35, y: 0.95),
                CGPoint(x: 0.20, y: 0.88),
                CGPoint(x: 0.18, y: 0.75),
            ]),
        ],
        "K": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.80, y: 0.05), CGPoint(x: 0.20, y: 0.50)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.80, y: 0.95)]),
        ],
        "L": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.95), CGPoint(x: 0.80, y: 0.95)]),
        ],
        "M": [
            StrokePath(points: [CGPoint(x: 0.10, y: 0.95), CGPoint(x: 0.10, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.10, y: 0.05), CGPoint(x: 0.50, y: 0.55)]),
            StrokePath(points: [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.90, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.90, y: 0.05), CGPoint(x: 0.90, y: 0.95)]),
        ],
        "N": [
            StrokePath(points: [CGPoint(x: 0.15, y: 0.95), CGPoint(x: 0.15, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.15, y: 0.05), CGPoint(x: 0.85, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.85, y: 0.95), CGPoint(x: 0.85, y: 0.05)]),
        ],
        "O": [
            StrokePath(points: [
                CGPoint(x: 0.50, y: 0.05),
                CGPoint(x: 0.78, y: 0.12),
                CGPoint(x: 0.90, y: 0.35),
                CGPoint(x: 0.90, y: 0.65),
                CGPoint(x: 0.78, y: 0.88),
                CGPoint(x: 0.50, y: 0.95),
                CGPoint(x: 0.22, y: 0.88),
                CGPoint(x: 0.10, y: 0.65),
                CGPoint(x: 0.10, y: 0.35),
                CGPoint(x: 0.22, y: 0.12),
                CGPoint(x: 0.50, y: 0.05),
            ]),
        ],
        "P": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [
                CGPoint(x: 0.20, y: 0.05),
                CGPoint(x: 0.72, y: 0.12),
                CGPoint(x: 0.80, y: 0.28),
                CGPoint(x: 0.72, y: 0.44),
                CGPoint(x: 0.20, y: 0.50),
            ]),
        ],
        "Q": [
            StrokePath(points: [
                CGPoint(x: 0.50, y: 0.05),
                CGPoint(x: 0.78, y: 0.12),
                CGPoint(x: 0.90, y: 0.35),
                CGPoint(x: 0.90, y: 0.65),
                CGPoint(x: 0.78, y: 0.88),
                CGPoint(x: 0.50, y: 0.95),
                CGPoint(x: 0.22, y: 0.88),
                CGPoint(x: 0.10, y: 0.65),
                CGPoint(x: 0.10, y: 0.35),
                CGPoint(x: 0.22, y: 0.12),
                CGPoint(x: 0.50, y: 0.05),
            ]),
            StrokePath(points: [CGPoint(x: 0.60, y: 0.72), CGPoint(x: 0.85, y: 0.95)]),
        ],
        "R": [
            StrokePath(points: [CGPoint(x: 0.20, y: 0.05), CGPoint(x: 0.20, y: 0.95)]),
            StrokePath(points: [
                CGPoint(x: 0.20, y: 0.05),
                CGPoint(x: 0.72, y: 0.12),
                CGPoint(x: 0.80, y: 0.28),
                CGPoint(x: 0.72, y: 0.44),
                CGPoint(x: 0.20, y: 0.50),
            ]),
            StrokePath(points: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.80, y: 0.95)]),
        ],
        "S": [
            StrokePath(points: [
                CGPoint(x: 0.78, y: 0.15),
                CGPoint(x: 0.60, y: 0.05),
                CGPoint(x: 0.35, y: 0.05),
                CGPoint(x: 0.18, y: 0.18),
                CGPoint(x: 0.20, y: 0.35),
                CGPoint(x: 0.40, y: 0.47),
                CGPoint(x: 0.60, y: 0.53),
                CGPoint(x: 0.80, y: 0.65),
                CGPoint(x: 0.82, y: 0.82),
                CGPoint(x: 0.65, y: 0.95),
                CGPoint(x: 0.35, y: 0.95),
                CGPoint(x: 0.18, y: 0.85),
            ]),
        ],
        "T": [
            StrokePath(points: [CGPoint(x: 0.10, y: 0.05), CGPoint(x: 0.90, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.50, y: 0.05), CGPoint(x: 0.50, y: 0.95)]),
        ],
        "U": [
            StrokePath(points: [
                CGPoint(x: 0.20, y: 0.05),
                CGPoint(x: 0.20, y: 0.75),
                CGPoint(x: 0.28, y: 0.88),
                CGPoint(x: 0.50, y: 0.95),
                CGPoint(x: 0.72, y: 0.88),
                CGPoint(x: 0.80, y: 0.75),
                CGPoint(x: 0.80, y: 0.05),
            ]),
        ],
        "V": [
            StrokePath(points: [CGPoint(x: 0.10, y: 0.05), CGPoint(x: 0.50, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.90, y: 0.05), CGPoint(x: 0.50, y: 0.95)]),
        ],
        "W": [
            StrokePath(points: [CGPoint(x: 0.05, y: 0.05), CGPoint(x: 0.25, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.25, y: 0.95), CGPoint(x: 0.50, y: 0.55)]),
            StrokePath(points: [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.75, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.75, y: 0.95), CGPoint(x: 0.95, y: 0.05)]),
        ],
        "X": [
            StrokePath(points: [CGPoint(x: 0.15, y: 0.05), CGPoint(x: 0.85, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.85, y: 0.05), CGPoint(x: 0.15, y: 0.95)]),
        ],
        "Y": [
            StrokePath(points: [CGPoint(x: 0.15, y: 0.05), CGPoint(x: 0.50, y: 0.50)]),
            StrokePath(points: [CGPoint(x: 0.85, y: 0.05), CGPoint(x: 0.50, y: 0.50)]),
            StrokePath(points: [CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.50, y: 0.95)]),
        ],
        "Z": [
            StrokePath(points: [CGPoint(x: 0.15, y: 0.05), CGPoint(x: 0.85, y: 0.05)]),
            StrokePath(points: [CGPoint(x: 0.85, y: 0.05), CGPoint(x: 0.15, y: 0.95)]),
            StrokePath(points: [CGPoint(x: 0.15, y: 0.95), CGPoint(x: 0.85, y: 0.95)]),
        ],
    ]

    static func strokes(for letter: String) -> [StrokePath] {
        paths[letter.uppercased()] ?? []
    }
}
