import AppKit

/// NSAlert sizes accessory views by their frame. Calculate wrapped label heights
/// at their final width before assigning the accessory frame.
final class SettingsForm: NSView {
    let intervalInput: NSTextField
    let launchAtLogin: NSButton
    let modePicker: NSPopUpButton
    override var isFlipped: Bool { true }

    init(minutes: Int, mode: DisplayMode, loginEnabled: Bool, needsApproval: Bool,
         target: AnyObject?, settingsAction: Selector?) {
        intervalInput = NSTextField(string: String(minutes))
        launchAtLogin = NSButton(checkboxWithTitle: "Spustiť po prihlásení do macOS", target: nil, action: nil)
        modePicker = NSPopUpButton(frame: .zero, pullsDown: false)
        super.init(frame: .zero)
        let width: CGFloat = 380
        var y: CGFloat = 0

        func add(_ view: NSView, height: CGFloat, gap: CGFloat = 12) {
            view.frame = NSRect(x: 0, y: y, width: width, height: height)
            addSubview(view)
            y += height + gap
        }
        func label(_ text: String, secondary: Bool = false, gap: CGFloat = 8) {
            let field = NSTextField(wrappingLabelWithString: text)
            field.font = .systemFont(ofSize: secondary ? 11 : 13)
            field.textColor = secondary ? .secondaryLabelColor : .labelColor
            field.preferredMaxLayoutWidth = width
            let measured = field.cell!.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: 10_000))
            add(field, height: ceil(measured.height) + 4, gap: gap)
        }

        label("Obnovovať každých (minúty):")
        add(intervalInput, height: 26, gap: 6)
        label("Celé číslo od 1 do 120.", secondary: true, gap: 20)

        label("Zobrazenie v hornom paneli:")
        modePicker.addItems(withTitles: DisplayMode.allCases.map(\.title))
        modePicker.selectItem(at: DisplayMode.allCases.firstIndex(of: mode) ?? 2)
        add(modePicker, height: 28, gap: 10)
        label("Σ = celkový čas · ▣ = čas obrazovky · ⚡ = zostávajúci čas", secondary: true)
        label("Čiara pod celkovým časom: červená časť označuje čas obrazovky, zelená zostávajúcu výdrž. Ak odhad chýba alebo je Mac na nabíjačke, súčet sa nezobrazí.", secondary: true, gap: 22)

        launchAtLogin.state = loginEnabled ? .on : .off
        add(launchAtLogin, height: 24, gap: 6)
        label(needsApproval
            ? "Automatické spúšťanie čaká na povolenie v nastaveniach macOS."
            : "Platí aj po reštarte Macu.", secondary: true, gap: 10)
        let systemSettings = NSButton(title: "Prihlasovacie položky macOS…", target: target, action: settingsAction)
        add(systemSettings, height: 32, gap: 0)
        frame = NSRect(x: 0, y: 0, width: width, height: y)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
