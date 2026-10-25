import Foundation

let base = Date(timeIntervalSince1970: 0)
func log(_ minutes: Int, _ event: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    return "\(formatter.string(from: base.addingTimeInterval(Double(minutes * 60)))) \(event)"
}
func check(_ rows: [(Int, String)], now: Int, expected: Int?, start: Int? = nil) {
    let result = screenSession(log: rows.map { log($0.0, $0.1) }.joined(separator: "\n"), now: base.addingTimeInterval(Double(now * 60)))
    assert(result.map { Int($0.seconds / 60) } == expected, "Wrong duration")
    if let start { assert(result?.start == base.addingTimeInterval(Double(start * 60))) }
}
check([], now: 100, expected: nil)
check([(0,"Display is turned on"),(10,"Using BATT"),(20,"Display is turned off"),(40,"Display is turned on")], now: 60, expected: 30, start: 10)
check([(0,"Display is turned on"),(10,"Using BATT"),(20,"Using BATT"),(30,"Using AC"),(40,"Using BATT")], now: 50, expected: 10, start: 40)
check([(10,"Using BATT"),(20,"Display is turned on"),(30,"Display is turned off")], now: 50, expected: 10)
check([(0,"Display is turned on"),(10,"Using BATT"),(20,"Using AC")], now: 50, expected: 40)
check([(0,"Display is turned on"),(10,"Using BATT"),(90,"Display is turned off")], now: 50, expected: 40)
assert(duration(3660) == "1h 01m")
assert(duration(0) == "0h 00m")
print("Passed: six screen-history scenarios and duration formatting")

let split = TimeBreakdown(screen: 2 * 3600, remaining: 6 * 3600)!
assert(split.total == 8 * 3600)
assert(split.usedFraction == 0.25)
assert(TimeBreakdown(screen: nil, remaining: 3600) == nil)
assert(TimeBreakdown(screen: 3600, remaining: nil) == nil)
assert(TimeBreakdown(screen: 0, remaining: 0) == nil)
assert(TimeBreakdown(screen: -1, remaining: 60) == nil)
assert(TimeBreakdown(screen: .infinity, remaining: 60) == nil)
assert(TimeBreakdown(screen: 0, remaining: 60)?.usedFraction == 0)
assert(TimeBreakdown(screen: 60, remaining: 0)?.usedFraction == 1)
print("Passed: total duration, proportional bar, and unavailable/invalid values")
