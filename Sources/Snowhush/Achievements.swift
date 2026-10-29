import AppKit
import QuartzCore

enum AchievementID: String, CaseIterable {
    case firstRustle = "first_rustle"
    case goldSeeker = "gold_seeker"
    case goldenHoarder = "golden_hoarder"
    case ghostBuster = "ghost_buster"
    case swifferPro = "swiffer_pro"
    case pumpkinSmasher = "pumpkin_smasher"
    case stormCaller = "storm_caller"
    case halloweenLord = "halloween_lord"

    var icon: String {
        switch self {
        case .firstRustle: "🍂"
        case .goldSeeker: "✨"
        case .goldenHoarder: "👑"
        case .ghostBuster: "🌀"
        case .swifferPro: "🧹"
        case .pumpkinSmasher: "🎃"
        case .stormCaller: "💨"
        case .halloweenLord: "🏆"
        }
    }

    var title: String {
        switch self {
        case .firstRustle: "First Rustle"
        case .goldSeeker: "Gold Seeker"
        case .goldenHoarder: "24k Autumn Alchemist"
        case .ghostBuster: "Ghost-Vac Master"
        case .swifferPro: "Witch Swiffer Pro"
        case .pumpkinSmasher: "Pumpkin Smasher"
        case .stormCaller: "Storm Caller"
        case .halloweenLord: "Lord of Halloween"
        }
    }

    var detail: String {
        switch self {
        case .firstRustle: "Sweep or clean your first autumn leaf drift."
        case .goldSeeker: "Catch or vacuum your first rare Golden Leaf."
        case .goldenHoarder: "Collect 10 rare Golden Leaves."
        case .ghostBuster: "Vacuum 300 leaves with the Ghost-Vac."
        case .swifferPro: "Clean 500 leaves with the Witch Swiffer."
        case .pumpkinSmasher: "Touch corner Jack-o'-lanterns or burst 8 falling pumpkins."
        case .stormCaller: "Summon a Halloween wind gust or use the Leaf Blower."
        case .halloweenLord: "Unlock every other Halloween achievement."
        }
    }

    var rewardText: String? {
        switch self {
        case .goldenHoarder: "Unlocks 👑 Royal 24k Gold Flame"
        case .ghostBuster: "Unlocks 👻 Ectoplasm Green Flame"
        case .swifferPro: "Unlocks 🔮 Spectral Violet Flame"
        case .halloweenLord: "Unlocks 3× Golden Leaf Rain"
        default: nil
        }
    }
}

final class AchievementsManager {
    static let shared = AchievementsManager()

    private let defaults = UserDefaults.standard
    private let unlockedKey = "spookhush.unlockedAchievements"
    private let goldenCountKey = "spookhush.goldenLeaves"
    private let vacuumedCountKey = "spookhush.vacuumedLeaves"
    private let sweptCountKey = "spookhush.sweptLeaves"
    private let pumpkinsCountKey = "spookhush.pumpkinsSmashed"
    private let gustsCountKey = "spookhush.gustsSummoned"

    private(set) var unlocked: Set<String>
    private(set) var goldenLeaves: Int
    private(set) var vacuumedLeaves: Float
    private(set) var sweptLeaves: Float
    private(set) var pumpkinsSmashed: Int
    private(set) var gustsSummoned: Int

    private var toastWindow: NSWindow?
    private var toastQueue: [AchievementID] = []
    private var showingToast = false
    private var panelWindow: NSWindow?
    var onUpdate: (() -> Void)?

    private init() {
        let saved = defaults.stringArray(forKey: unlockedKey) ?? []
        unlocked = Set(saved)
        goldenLeaves = defaults.integer(forKey: goldenCountKey)
        vacuumedLeaves = defaults.float(forKey: vacuumedCountKey)
        sweptLeaves = defaults.float(forKey: sweptCountKey)
        pumpkinsSmashed = defaults.integer(forKey: pumpkinsCountKey)
        gustsSummoned = defaults.integer(forKey: gustsCountKey)
    }

    func isUnlocked(_ id: AchievementID) -> Bool {
        unlocked.contains(id.rawValue)
    }

    func isFlameUnlocked(_ theme: FlameTheme) -> Bool {
        switch theme {
        case .classicAmber: true
        case .royalGold: isUnlocked(.goldenHoarder)
        case .ectoplasmGreen: isUnlocked(.ghostBuster)
        case .spectralViolet: isUnlocked(.swifferPro)
        }
    }

    var goldenSpawnMultiplier: Float {
        isUnlocked(.halloweenLord) ? 3.0 : 1.0
    }

    var unlockedCount: Int { unlocked.count }
    var totalCount: Int { AchievementID.allCases.count }
    var goldenLeavesCollected: Int { goldenLeaves }

    func progress(for id: AchievementID) -> (current: Int, target: Int) {
        switch id {
        case .firstRustle: return (min(1, Int(sweptLeaves + vacuumedLeaves > 0 ? 1 : 0)), 1)
        case .goldSeeker: return (min(1, goldenLeaves), 1)
        case .goldenHoarder: return (min(10, goldenLeaves), 10)
        case .ghostBuster: return (min(300, Int(vacuumedLeaves)), 300)
        case .swifferPro: return (min(500, Int(sweptLeaves)), 500)
        case .pumpkinSmasher: return (min(8, pumpkinsSmashed), 8)
        case .stormCaller: return (min(1, gustsSummoned), 1)
        case .halloweenLord:
            let others = AchievementID.allCases.filter { $0 != .halloweenLord }
            let done = others.filter { isUnlocked($0) }.count
            return (done, others.count)
        }
    }

    // MARK: - Event Recording

    func recordFirstRustle() {
        check(.firstRustle)
    }

    func recordGoldenLeaf() {
        goldenLeaves += 1
        defaults.set(goldenLeaves, forKey: goldenCountKey)
        check(.goldSeeker)
        if goldenLeaves >= 10 {
            check(.goldenHoarder)
        }
        notifyPanel()
    }

    func recordVacuumed(_ count: Int) {
        recordVacuumed(amount: Float(count))
    }

    func recordVacuumed(amount: Float) {
        guard amount > 0 else { return }
        vacuumedLeaves += amount
        defaults.set(vacuumedLeaves, forKey: vacuumedCountKey)
        check(.firstRustle)
        if vacuumedLeaves >= 300 {
            check(.ghostBuster)
        }
    }

    func recordSwept(_ count: Int) {
        recordSwept(amount: Float(count), withSwiffer: true, withBlower: false)
    }

    func recordSwept(amount: Float, withSwiffer: Bool, withBlower: Bool) {
        guard amount > 0 else { return }
        check(.firstRustle)
        if withSwiffer {
            sweptLeaves += amount
            defaults.set(sweptLeaves, forKey: sweptCountKey)
            if sweptLeaves >= 500 {
                check(.swifferPro)
            }
        }
        if withBlower {
            recordGust()
        }
    }

    func recordPumpkinInteraction() {
        pumpkinsSmashed += 1
        defaults.set(pumpkinsSmashed, forKey: pumpkinsCountKey)
        if pumpkinsSmashed >= 8 {
            check(.pumpkinSmasher)
        }
        notifyPanel()
    }

    func recordGust() {
        gustsSummoned += 1
        defaults.set(gustsSummoned, forKey: gustsCountKey)
        check(.stormCaller)
        notifyPanel()
    }

    private func check(_ id: AchievementID) {
        guard !isUnlocked(id) else { return }
        unlocked.insert(id.rawValue)
        defaults.set(Array(unlocked), forKey: unlockedKey)
        SoundEngine.shared.noteAchievementUnlocked()
        DispatchQueue.main.async {
            self.enqueueToast(id)
            self.notifyPanel()
        }

        // Check master achievement
        if id != .halloweenLord {
            let others = AchievementID.allCases.filter { $0 != .halloweenLord }
            if others.allSatisfy({ isUnlocked($0) }) {
                check(.halloweenLord)
            }
        }
    }

    private func notifyPanel() {
        DispatchQueue.main.async {
            self.onUpdate?()
            if self.panelWindow?.isVisible == true {
                self.rebuildPanelContent()
            }
        }
    }

    // MARK: - Floating Achievement Toast Banner

    private func enqueueToast(_ id: AchievementID) {
        toastQueue.append(id)
        showNextToastIfNeeded()
    }

    private func showNextToastIfNeeded() {
        guard !showingToast, !toastQueue.isEmpty else { return }
        showingToast = true
        let id = toastQueue.removeFirst()

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            showingToast = false
            return
        }

        let width: CGFloat = 360
        let height: CGFloat = id.rewardText != nil ? 86 : 70
        let frame = screen.visibleFrame
        let targetOrigin = CGPoint(x: frame.midX - width / 2, y: frame.maxY - height - 18)
        let startOrigin = CGPoint(x: targetOrigin.x, y: frame.maxY + 20)

        let window = NSPanel(
            contentRect: CGRect(origin: startOrigin, size: CGSize(width: width, height: height)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.hasShadow = true

        let card = NSView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor(srgbRed: 0.11, green: 0.06, blue: 0.15, alpha: 0.96).cgColor
        card.layer?.cornerRadius = 14
        card.layer?.borderWidth = 1.5
        card.layer?.borderColor = NSColor(srgbRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.85).cgColor

        let badge = NSTextField(labelWithString: id.icon)
        badge.font = .systemFont(ofSize: 32)
        badge.frame = CGRect(x: 16, y: (height - 38) / 2, width: 42, height: 38)
        card.addSubview(badge)

        let kicker = NSTextField(labelWithString: "ACHIEVEMENT UNLOCKED")
        kicker.font = .systemFont(ofSize: 10, weight: .bold)
        kicker.textColor = NSColor(srgbRed: 1.0, green: 0.76, blue: 0.24, alpha: 1.0)
        kicker.frame = CGRect(x: 66, y: height - 24, width: width - 80, height: 14)
        card.addSubview(kicker)

        let titleLabel = NSTextField(labelWithString: id.title)
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = NSColor(srgbRed: 0.98, green: 0.92, blue: 0.84, alpha: 1.0)
        titleLabel.frame = CGRect(x: 66, y: height - 44, width: width - 80, height: 20)
        card.addSubview(titleLabel)

        let subText = id.rewardText ?? id.detail
        let subLabel = NSTextField(labelWithString: subText)
        subLabel.font = .systemFont(ofSize: 11.5, weight: id.rewardText != nil ? .semibold : .regular)
        subLabel.textColor = id.rewardText != nil
            ? NSColor(srgbRed: 0.45, green: 0.96, blue: 0.58, alpha: 1.0)
            : NSColor(srgbRed: 0.84, green: 0.76, blue: 0.70, alpha: 0.9)
        subLabel.frame = CGRect(x: 66, y: 10, width: width - 80, height: 18)
        card.addSubview(subLabel)

        window.contentView = card
        window.alphaValue = 0
        window.orderFrontRegardless()
        self.toastWindow = window

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrameOrigin(targetOrigin)
            window.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) { [weak self] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().setFrameOrigin(startOrigin)
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.close()
                self?.toastWindow = nil
                self?.showingToast = false
                self?.showNextToastIfNeeded()
            })
        }
    }

    // MARK: - Trophies & Golden Leaves Window

    func showAchievementsWindow() {
        if let existing = panelWindow {
            rebuildPanelContent()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let width: CGFloat = 500
        let height: CGFloat = 610
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let rect = CGRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.midY - height / 2,
            width: width,
            height: height
        )

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Spookhush Trophies & Golden Leaves"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(srgbRed: 0.09, green: 0.05, blue: 0.12, alpha: 1.0)
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.panelWindow = window

        rebuildPanelContent()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func rebuildPanelContent() {
        guard let window = panelWindow else { return }
        let width: CGFloat = 500
        let height: CGFloat = 610
        let root = NSView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(srgbRed: 0.09, green: 0.05, blue: 0.12, alpha: 1.0).cgColor

        // Header
        let headerTitle = NSTextField(labelWithString: "🎃 SPOOKHUSH TROPHIES")
        headerTitle.font = .systemFont(ofSize: 20, weight: .heavy)
        headerTitle.textColor = NSColor(srgbRed: 1.0, green: 0.64, blue: 0.18, alpha: 1.0)
        headerTitle.frame = CGRect(x: 24, y: height - 52, width: 300, height: 26)
        root.addSubview(headerTitle)

        // Golden Leaf Counter Pill
        let goldPill = NSView(frame: CGRect(x: width - 178, y: height - 56, width: 154, height: 32))
        goldPill.wantsLayer = true
        goldPill.layer?.backgroundColor = NSColor(srgbRed: 0.24, green: 0.16, blue: 0.06, alpha: 1.0).cgColor
        goldPill.layer?.cornerRadius = 16
        goldPill.layer?.borderWidth = 1
        goldPill.layer?.borderColor = NSColor(srgbRed: 1.0, green: 0.80, blue: 0.22, alpha: 0.8).cgColor

        let goldLabel = NSTextField(labelWithString: "✨ \(goldenLeaves) Golden Leaves")
        goldLabel.font = .systemFont(ofSize: 12.5, weight: .bold)
        goldLabel.textColor = NSColor(srgbRed: 1.0, green: 0.86, blue: 0.28, alpha: 1.0)
        goldLabel.alignment = .center
        goldLabel.frame = CGRect(x: 6, y: 6, width: 142, height: 19)
        goldPill.addSubview(goldLabel)
        root.addSubview(goldPill)

        // Achievement rows
        var y = height - 112
        for id in AchievementID.allCases {
            let done = isUnlocked(id)
            let prog = progress(for: id)

            let row = NSView(frame: CGRect(x: 20, y: y, width: width - 40, height: 52))
            row.wantsLayer = true
            row.layer?.backgroundColor = done
                ? NSColor(srgbRed: 0.18, green: 0.11, blue: 0.22, alpha: 0.95).cgColor
                : NSColor(srgbRed: 0.13, green: 0.08, blue: 0.16, alpha: 0.75).cgColor
            row.layer?.cornerRadius = 10
            row.layer?.borderWidth = 1
            row.layer?.borderColor = done
                ? NSColor(srgbRed: 1.0, green: 0.68, blue: 0.20, alpha: 0.65).cgColor
                : NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.08).cgColor

            let iconField = NSTextField(labelWithString: done ? id.icon : "🔒")
            iconField.font = .systemFont(ofSize: 22)
            iconField.frame = CGRect(x: 12, y: 12, width: 32, height: 28)
            row.addSubview(iconField)

            let nameField = NSTextField(labelWithString: id.title)
            nameField.font = .systemFont(ofSize: 13.5, weight: .bold)
            nameField.textColor = done
                ? NSColor(srgbRed: 1.0, green: 0.92, blue: 0.82, alpha: 1.0)
                : NSColor(srgbRed: 0.72, green: 0.66, blue: 0.75, alpha: 1.0)
            nameField.frame = CGRect(x: 48, y: 27, width: 250, height: 18)
            row.addSubview(nameField)

            let descField = NSTextField(labelWithString: id.detail)
            descField.font = .systemFont(ofSize: 11.5)
            descField.textColor = NSColor(srgbRed: 0.78, green: 0.70, blue: 0.66, alpha: 0.9)
            descField.frame = CGRect(x: 48, y: 8, width: 310, height: 16)
            row.addSubview(descField)

            let statusText = done ? "UNLOCKED ✓" : "\(prog.current) / \(prog.target)"
            let statusField = NSTextField(labelWithString: statusText)
            statusField.font = .systemFont(ofSize: 11, weight: .bold)
            statusField.alignment = .right
            statusField.textColor = done
                ? NSColor(srgbRed: 0.45, green: 0.95, blue: 0.58, alpha: 1.0)
                : NSColor(srgbRed: 0.95, green: 0.65, blue: 0.30, alpha: 0.9)
            statusField.frame = CGRect(x: width - 150, y: 27, width: 98, height: 16)
            row.addSubview(statusField)

            if let reward = id.rewardText {
                let rewardField = NSTextField(labelWithString: reward)
                rewardField.font = .systemFont(ofSize: 10, weight: .medium)
                rewardField.alignment = .right
                rewardField.textColor = NSColor(srgbRed: 1.0, green: 0.78, blue: 0.32, alpha: 0.9)
                rewardField.frame = CGRect(x: width - 210, y: 8, width: 158, height: 14)
                row.addSubview(rewardField)
            }

            root.addSubview(row)
            y -= 58
        }

        // Footer: Lantern Flame Color selector
        let flameTitle = NSTextField(labelWithString: "LANTERN & PUMPKIN FLAME COLOR (UNLOCKED BY TROPHIES):")
        flameTitle.font = .systemFont(ofSize: 10.5, weight: .bold)
        flameTitle.textColor = NSColor(srgbRed: 0.85, green: 0.75, blue: 0.68, alpha: 0.85)
        flameTitle.frame = CGRect(x: 24, y: 46, width: width - 48, height: 16)
        root.addSubview(flameTitle)

        var bx: CGFloat = 20
        for theme in FlameTheme.allCases {
            let unlockedTheme = isFlameUnlocked(theme)
            let isSelected = Preferences.flameTheme == theme
            let btn = NSButton(frame: CGRect(x: bx, y: 14, width: 110, height: 28))
            btn.bezelStyle = .rounded
            btn.title = unlockedTheme ? theme.title : "🔒 Locked"
            btn.font = .systemFont(ofSize: 10.5, weight: isSelected ? .bold : .regular)
            btn.isEnabled = unlockedTheme
            btn.tag = theme.rawValue
            btn.target = self
            btn.action = #selector(selectFlameTheme(_:))
            root.addSubview(btn)
            bx += 116
        }

        window.contentView = root
    }

    @objc private func selectFlameTheme(_ sender: NSButton) {
        guard let theme = FlameTheme(rawValue: sender.tag), isFlameUnlocked(theme) else { return }
        Preferences.flameTheme = theme
        SoundEngine.shared.noteGoldenCatch()
        rebuildPanelContent()
        onUpdate?()
    }
}
