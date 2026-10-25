import Foundation

struct ScreenSession {
    let start: Date
    let seconds: TimeInterval
}

func duration(_ seconds: TimeInterval) -> String {
    let minutes = max(0, Int(seconds / 60))
    return "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
}

// Same measurement as battery_time.sh: display-on time since the last AC → battery transition.
// Available log history is the source of truth, including time while this app was closed.
func screenSession(log: String, now: Date = Date()) -> ScreenSession? {
    enum Kind { case on, off, battery, ac }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    var events: [(Date, Kind)] = []
    for line in log.split(separator: "\n") {
        let kind: Kind
        if line.contains("Display is turned on") { kind = .on }
        else if line.contains("Display is turned off") { kind = .off }
        else if line.range(of: #"Using BATT\b"#, options: [.regularExpression, .caseInsensitive]) != nil { kind = .battery }
        else if line.range(of: #"Using AC\b"#, options: [.regularExpression, .caseInsensitive]) != nil { kind = .ac }
        else { continue }
        guard line.count >= 25, let date = formatter.date(from: String(line.prefix(25))), date <= now else { continue }
        events.append((date, kind))
    }
    events = events.enumerated().sorted {
        $0.element.0 == $1.element.0 ? $0.offset < $1.offset : $0.element.0 < $1.element.0
    }.map(\.element)
    var previousSource: Kind?
    var start: Date?
    for (date, kind) in events where kind == .battery || kind == .ac {
        if kind == .battery && previousSource != .battery { start = date }
        previousSource = kind
    }
    guard let start else { return nil }
    var displayOn = false
    var previous = start
    var total: TimeInterval = 0
    for (date, kind) in events {
        if date < start {
            if kind == .on { displayOn = true }
            if kind == .off { displayOn = false }
            continue
        }
        if displayOn { total += max(0, date.timeIntervalSince(previous)) }
        if kind == .on { displayOn = true }
        if kind == .off { displayOn = false }
        previous = date
    }
    if displayOn { total += max(0, now.timeIntervalSince(previous)) }
    return ScreenSession(start: start, seconds: total)
}
