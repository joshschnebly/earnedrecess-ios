enum WordAssociationLibrary {
    private static let associations: [String: (String, String)] = [
        "A": ("🍎", "Apple"), "B": ("🎾", "Ball"), "C": ("🐱", "Cat"),
        "D": ("🐶", "Dog"), "E": ("🥚", "Egg"), "F": ("🐟", "Fish"),
        "G": ("🐐", "Goat"), "H": ("🎩", "Hat"), "I": ("🏔", "Igloo"),
        "J": ("🫙", "Jar"), "K": ("🪁", "Kite"), "L": ("🦁", "Lion"),
        "M": ("🌙", "Moon"), "N": ("🪺", "Nest"), "O": ("🍊", "Orange"),
        "P": ("🍕", "Pizza"), "Q": ("👑", "Queen"), "R": ("🌧", "Rain"),
        "S": ("☀️", "Sun"), "T": ("🌳", "Tree"), "U": ("☂️", "Umbrella"),
        "V": ("🚐", "Van"), "W": ("💧", "Water"), "X": ("🩻", "X-ray"),
        "Y": ("🧶", "Yarn"), "Z": ("🦓", "Zebra")
    ]

    static func emoji(for letter: String) -> String {
        associations[letter.uppercased()]?.0 ?? "?"
    }

    static func word(for letter: String) -> String {
        associations[letter.uppercased()]?.1 ?? letter
    }
}
