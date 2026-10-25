import AppKit
import IOKit.ps
import ServiceManagement

struct Reading {
    let screen: ScreenSession?
    let battery: String
    let detail: String
    let error: String?
    var remaining: TimeInterval? = nil
}

func readBattery() -> (String, String, TimeInterval?) {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
        return ("—", "Údaje o batérii nie sú dostupné", nil)
    }
    for source in sources {
        guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
              description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
        let current = (description[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue ?? 0
        let maximum = (description[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue ?? 100
        let percent = Int(current / max(1, maximum) * 100)
        if description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue {
            let charging = description[kIOPSIsChargingKey] as? Bool ?? false
            return ("AC", "Batéria: \(percent) % · \(charging ? "nabíja sa" : "napájanie zo siete")", nil)
        }
        let seconds = IOPSGetTimeRemainingEstimate()
        let minutes = (description[kIOPSTimeToEmptyKey] as? NSNumber)?.doubleValue ?? -1
        let estimate = seconds > 0 ? seconds : (minutes > 0 ? minutes * 60 : -1)
        return (estimate > 0 ? duration(estimate) : "…", "Batéria: \(percent) % · \(estimate > 0 ? "odhad podľa macOS" : "macOS zatiaľ počíta výdrž")", estimate > 0 ? estimate : nil)
    }
    return ("—", "Interná batéria sa nenašla", nil)
}

func readStats() -> Reading {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["-g", "log"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    let battery = readBattery()
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return Reading(screen: nil, battery: battery.0, detail: battery.1, error: "Systémové záznamy sa nepodarilo načítať", remaining: battery.2)
        }
        return Reading(screen: screenSession(log: String(decoding: data, as: UTF8.self)), battery: battery.0, detail: battery.1, error: nil, remaining: battery.2)
    } catch {
        return Reading(screen: nil, battery: battery.0, detail: battery.1, error: error.localizedDescription, remaining: battery.2)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem!
    private var timer: Timer?
    private var busy = false
    private var reading: Reading?
    private var observers: [NSObjectProtocol] = []
    private var displayMode: DisplayMode {
        DisplayMode(rawValue: UserDefaults.standard.string(forKey: "displayMode") ?? "") ?? .both
    }
    private var interval: Double {
        let saved = UserDefaults.standard.double(forKey: "refreshMinutes")
        return saved >= 1 && saved <= 120 ? saved : 1
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Opening the bundle again should never produce duplicate status items.
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.BatteryTime")
        if others.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil); return
        }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        updateStatus()
        item.button?.toolTip = "Čas obrazovky od odpojenia nabíjačky · zostávajúca výdrž"
        rebuildMenu()
        schedule()
        refresh()
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() })
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval * 60, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = min(5, interval * 3)
    }

    @objc private func refresh() {
        guard !busy else { return }
        busy = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = readStats()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.reading = result
                self.busy = false
                self.updateStatus()
                self.rebuildMenu()
            }
        }
    }

    private func updateStatus() {
        guard let button = item.button else { return }
        let screen = reading?.screen.map { duration($0.seconds) } ?? "—"
        let remaining = reading?.battery ?? "…"
        button.image = nil
        button.imagePosition = .noImage
        switch displayMode {
        case .remaining:
            button.title = "⚡ \(remaining)"
            button.toolTip = "Zostávajúca výdrž: \(remaining)"
        case .screen:
            button.title = "▣ \(screen)"
            button.toolTip = "Čas zapnutej obrazovky: \(screen)"
        case .both:
            button.title = "▣ \(screen) · ⚡ \(remaining)"
            button.toolTip = "Čas obrazovky: \(screen) · zostáva: \(remaining)"
        case .total, .totalRemaining, .totalScreen, .all:
            let breakdown = TimeBreakdown(screen: reading?.screen?.seconds, remaining: reading?.remaining)
            let text = breakdown.map { "Σ \(duration($0.total))" } ?? "Σ —"
            let image = totalStatusImage(text: text, breakdown: breakdown)
            button.title = displayMode.additionalTimes(screen: screen, remaining: remaining)
            button.image = image
            button.imagePosition = button.title.isEmpty ? .imageOnly : .imageLeading
            button.toolTip = breakdown.map { "Spolu: \(duration($0.total)) · červená: obrazovka \(screen) · zelená: zostáva \(remaining)" }
                ?? "Súčet nie je dostupný · obrazovka: \(screen) · zostáva: \(remaining)"
        }
        button.setAccessibilityLabel(button.toolTip)
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        func label(_ title: String) {
            let row = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            row.isEnabled = false
            menu.addItem(row)
        }
        let total = TimeBreakdown(screen: reading?.screen?.seconds, remaining: reading?.remaining)
        label("Celkový čas: \(total.map { duration($0.total) } ?? "—")")
        label("Čas obrazovky: \(reading?.screen.map { duration($0.seconds) } ?? "—")")
        let remaining = reading?.remaining.map { duration($0) }
            ?? (reading?.battery == "AC" ? "napájanie zo siete" : "odhad nie je dostupný")
        label("Zostávajúci čas: \(reading == nil ? "načítavam…" : remaining)")
        if let error = reading?.error { label(error) }
        menu.addItem(.separator())
        let refreshItem = menu.addItem(withTitle: busy ? "Obnovujem…" : "Obnoviť teraz", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.isEnabled = !busy
        menu.addItem(withTitle: "Nastavenia…", action: #selector(settings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "O meraní…", action: #selector(about), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Ukončiť BatteryTime", action: #selector(quit), keyEquivalent: "q").target = self
        item.menu = menu
    }

    @objc private func settings() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Nastavenia BatteryTime"
        alert.informativeText = "Vyber spôsob zobrazenia a správanie aplikácie. Zmeny sa použijú po uložení."
        let form = SettingsForm(minutes: Int(interval), mode: displayMode,
            loginEnabled: SMAppService.mainApp.status == .enabled,
            needsApproval: SMAppService.mainApp.status == .requiresApproval,
            target: self, settingsAction: #selector(openLoginSettings))
        let input = form.intervalInput
        let launchAtLogin = form.launchAtLogin
        let modePicker = form.modePicker
        alert.accessoryView = form
        alert.addButton(withTitle: "Uložiť")
        alert.addButton(withTitle: "Zrušiť")
        alert.window.initialFirstResponder = input
        while alert.runModal() == .alertFirstButtonReturn {
            guard let value = Int(input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)), (1...120).contains(value) else {
                alert.informativeText = "Zadaj platné celé číslo od 1 do 120 minút."
                continue
            }
            do {
                let service = SMAppService.mainApp
                if launchAtLogin.state == .on {
                    if service.status != .enabled && service.status != .requiresApproval {
                        try service.register()
                    }
                    if service.status == .requiresApproval {
                        let approval = NSAlert()
                        approval.messageText = "Povoľ automatické spúšťanie v macOS"
                        approval.informativeText = "macOS vyžaduje povolenie BatteryTime v Prihlasovacích položkách."
                        approval.addButton(withTitle: "Otvoriť nastavenia macOS")
                        approval.addButton(withTitle: "Neskôr")
                        if approval.runModal() == .alertFirstButtonReturn {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                    }
                } else if service.status == .enabled || service.status == .requiresApproval {
                    try service.unregister()
                }
            } catch {
                alert.informativeText = "Automatické spúšťanie sa nepodarilo zmeniť: \(error.localizedDescription)"
                continue
            }
            UserDefaults.standard.set(value, forKey: "refreshMinutes")
            UserDefaults.standard.set(DisplayMode.allCases[modePicker.indexOfSelectedItem].rawValue, forKey: "displayMode")
            updateStatus()
            schedule()
            refresh()
            break
        }
    }

    @objc private func openLoginSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Čas obrazovky a výdrž batérie"
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            alert.icon = icon
        }
        alert.informativeText = "▣ = čas zapnutej obrazovky od posledného odpojenia nabíjačky podľa pmset, rovnako ako battery_time.sh. Po pripojení ďalej pribúda; ďalšie odpojenie začne nové meranie. Nie je to systémový Čas pred obrazovkou.\n\n⚡ = zostávajúca výdrž podľa macOS. AC znamená napájanie zo siete, … znamená, že odhad ešte nie je dostupný.\n\nHistória môže byť neúplná po vymazaní systémových záznamov. Aplikácia nič neposiela na internet."
        alert.runModal()
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

if CommandLine.arguments.contains("--login-status") {
    print("Login status: \(SMAppService.mainApp.status.rawValue)")
} else if CommandLine.arguments.contains("--enable-login") {
    do {
        if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
        print("Login status: \(SMAppService.mainApp.status.rawValue)")
    } catch {
        fputs("Login registration failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else if CommandLine.arguments.contains("--diagnose") {
    let result = readStats()
    print("Obrazovka: \(result.screen.map { duration($0.seconds) } ?? "—")")
    print("Výdrž: \(result.battery) · \(result.detail)")
    if let error = result.error { print(error) }
} else {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
