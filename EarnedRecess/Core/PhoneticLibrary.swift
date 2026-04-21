enum PhoneticLibrary {
    private static let phonetics: [String: String] = [
        "A": "Ah", "B": "Buh", "C": "Kuh", "D": "Duh", "E": "Eh",
        "F": "Fuh", "G": "Guh", "H": "Huh", "I": "Ih", "J": "Juh",
        "K": "Kuh", "L": "Luh", "M": "Muh", "N": "Nuh", "O": "Oh",
        "P": "Puh", "Q": "Kwuh", "R": "Ruh", "S": "Suh", "T": "Tuh",
        "U": "Uh", "V": "Vuh", "W": "Wuh", "X": "Ksuh", "Y": "Yuh",
        "Z": "Zuh"
    ]

    private static let examples: [String: String] = [
        "A": "Apple", "B": "Ball", "C": "Cat", "D": "Dog", "E": "Egg",
        "F": "Fish", "G": "Goat", "H": "Hat", "I": "Igloo", "J": "Jar",
        "K": "Kite", "L": "Lion", "M": "Moon", "N": "Nest", "O": "Orange",
        "P": "Pizza", "Q": "Queen", "R": "Rain", "S": "Sun", "T": "Tree",
        "U": "Umbrella", "V": "Van", "W": "Water", "X": "X-ray", "Y": "Yarn",
        "Z": "Zebra"
    ]

    static func phonetic(for letter: String) -> String {
        phonetics[letter.uppercased()] ?? letter
    }

    static func exampleWord(for letter: String) -> String {
        examples[letter.uppercased()] ?? letter
    }
}
