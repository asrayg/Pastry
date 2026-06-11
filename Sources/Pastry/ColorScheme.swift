import SwiftUI

enum PastryTheme: String, CaseIterable, Identifiable {
    case sunset   = "Sunset"
    case ocean    = "Ocean"
    case forest   = "Forest"
    case candy    = "Candy"
    case mono     = "Mono"

    var id: String { rawValue }

    var gradient: LinearGradient {
        switch self {
        case .sunset:
            return LinearGradient(colors: [Color(hex: 0xFF9E6B), Color(hex: 0xF05A8D)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(colors: [Color(hex: 0x4FC3F7), Color(hex: 0x5C6BC0)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [Color(hex: 0x66BB6A), Color(hex: 0x00897B)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .candy:
            return LinearGradient(colors: [Color(hex: 0xF48FB1), Color(hex: 0xCE93D8)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mono:
            return LinearGradient(colors: [Color(hex: 0x9E9E9E), Color(hex: 0x424242)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var accent: Color {
        switch self {
        case .sunset: return Color(hex: 0xF05A8D)
        case .ocean:  return Color(hex: 0x5C6BC0)
        case .forest: return Color(hex: 0x00897B)
        case .candy:  return Color(hex: 0xCE93D8)
        case .mono:   return Color(hex: 0x757575)
        }
    }

    // Badge colors for text / image rows
    var textBadgeColor: Color {
        switch self {
        case .sunset: return Color(hex: 0xFF9E6B)
        case .ocean:  return Color(hex: 0x4FC3F7)
        case .forest: return Color(hex: 0x66BB6A)
        case .candy:  return Color(hex: 0xF48FB1)
        case .mono:   return Color(hex: 0x9E9E9E)
        }
    }
    var imageBadgeColor: Color {
        switch self {
        case .sunset: return Color(hex: 0xF05A8D)
        case .ocean:  return Color(hex: 0x5C6BC0)
        case .forest: return Color(hex: 0x00897B)
        case .candy:  return Color(hex: 0xCE93D8)
        case .mono:   return Color(hex: 0x616161)
        }
    }
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()
    private static let key = "pastryTheme"

    @Published var current: PastryTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: Self.key) }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.key) ?? ""
        current = PastryTheme(rawValue: saved) ?? .sunset
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
