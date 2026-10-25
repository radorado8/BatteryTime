import Foundation

enum DisplayMode: String, CaseIterable {
    case remaining, screen, both, total, totalRemaining, totalScreen, all

    func additionalTimes(screen: String, remaining: String) -> String {
        switch self {
        case .totalRemaining: return " · ⚡ \(remaining)"
        case .totalScreen: return " · ▣ \(screen)"
        case .all: return " · ▣ \(screen) · ⚡ \(remaining)"
        default: return ""
        }
    }

    var title: String {
        switch self {
        case .remaining: return "Iba zostávajúci čas"
        case .screen: return "Iba čas zapnutej obrazovky"
        case .both: return "Čas obrazovky aj zostávajúci čas"
        case .total: return "Súčet časov s farebnou čiarou"
        case .totalRemaining: return "Celkový a zostávajúci čas"
        case .totalScreen: return "Celkový čas a čas obrazovky"
        case .all: return "Všetky tri časy"
        }
    }
}

struct TimeBreakdown {
    let total: TimeInterval
    let usedFraction: Double

    init?(screen: TimeInterval?, remaining: TimeInterval?) {
        guard let screen, let remaining,
              screen.isFinite, remaining.isFinite, screen >= 0, remaining >= 0,
              (screen + remaining).isFinite, screen + remaining > 0 else { return nil }
        total = screen + remaining
        usedFraction = screen / total
    }
}
