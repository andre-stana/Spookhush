import AppKit
import QuartzCore

enum AchievementID: String, CaseIterable {
    case firstRustle = "first_rustle"
    case goldSeeker = "gold_seeker"
    case goldenHoarder = "golden_hoarder"
    case autumnAlchemist = "autumn_alchemist"
    case dragonsHoard = "dragons_hoard"
    case comboHunter = "combo_hunter"
    case ghostBuster = "ghost_buster"
    case poltergeistCleaner = "poltergeist_cleaner"
    case swifferPro = "swiffer_pro"
    case grandSorcererBroom = "grand_sorcerer_broom"
    case hurricaneMaster = "hurricane_master"
    case pumpkinSmasher = "pumpkin_smasher"
    case pumpkinDemolisher = "pumpkin_demolisher"
    case hauntedArchitect = "haunted_architect"
    case midnightWatcher = "midnight_watcher"
    case halloweenLord = "halloween_lord"

    var icon: String {
        switch self {
        case .firstRustle: "🍂"
        case .goldSeeker: "✨"
        case .goldenHoarder: "🪙"
        case .autumnAlchemist: "👑"
        case .dragonsHoard: "🐉"
        case .comboHunter: "⚡"
        case .ghostBuster: "🌀"
        case .poltergeistCleaner: "🌪️"
        case .swifferPro: "🧹"
        case .grandSorcererBroom: "🪄"
        case .hurricaneMaster: "💨"
        case .pumpkinSmasher: "🎃"
        case .pumpkinDemolisher: "💥"
        case .hauntedArchitect: "🪟"
        case .midnightWatcher: "🌙"
        case .halloweenLord: "🏆"
        }
    }

    var title: String {
        switch self {
        case .firstRustle: "First Rustle"
        case .goldSeeker: "Gold Seeker"
        case .goldenHoarder: "Golden Collector"
        case .autumnAlchemist: "24k Autumn Alchemist"
        case .dragonsHoard: "Dragon's Hoard"
        case .comboHunter: "Golden Combo ×5"
        case .ghostBuster: "Ghost-Vac Apprentice"
        case .poltergeistCleaner: "Poltergeist Cleaner"
        case .swifferPro: "Witch Swiffer Pro"
        case .grandSorcererBroom: "Grand Sorcerer's Broom"
        case .hurricaneMaster: "Hurricane Master"
        case .pumpkinSmasher: "Pumpkin Whisperer"
        case .pumpkinDemolisher: "Jack-o'-Lantern Demolisher"
        case .hauntedArchitect: "Haunted Architect"
        case .midnightWatcher: "Midnight Watcher"
        case .halloweenLord: "Overlord of Halloween"
        }
    }

    var detail: String {
        switch self {
        case .firstRustle: "Sweep or clean your first autumn leaf drift."
        case .goldSeeker: "Catch your first shimmering 24k Golden Leaf."
        case .goldenHoarder: "Collect 25 rare 24k Golden Leaves."
        case .autumnAlchemist: "Collect 100 rare 24k Golden Leaves."
        case .dragonsHoard: "Amass a legendary hoard of 500 Golden Leaves."
        case .comboHunter: "Catch 5 Golden Leaves within 12s of each other."
        case .ghostBuster: "Vacuum 1,000 leaves with the Ghost-Vac."
        case .poltergeistCleaner: "Vacuum 10,000 leaves with the Ghost-Vac."
        case .swifferPro: "Sweep 2,000 leaves with the Witch Swiffer."
        case .grandSorcererBroom: "Sweep 15,000 leaves with the Witch Swiffer."
        case .hurricaneMaster: "Blast 5,000 leaves with the Leaf Blower or Wind Gusts."
        case .pumpkinSmasher: "Awaken Corner Jack-o'-lanterns or burst 50 pumpkins."
        case .pumpkinDemolisher: "Awaken or burst 250 Jack-o'-lantern pumpkins."
        case .hauntedArchitect: "Slide or drop 2,500 leaves off your desktop windows."
        case .midnightWatcher: "Keep Spookhush active on your desktop for 180 minutes."
        case .halloweenLord: "Unlock all 15 other Halloween achievements."
        }
    }

    var rewardText: String? {
        switch self {
        case .goldenHoarder: "Unlocks 👑 24k Gold Flame"
        case .autumnAlchemist: "Unlocks ✨ Golden Cursor Trail"
        case .dragonsHoard: "Unlocks 🔥 Hellfire Crimson Flame"
        case .comboHunter: "Unlocks ⚡ 2× Golden Fever Duration"
        case .ghostBuster: "Unlocks 👻 Ectoplasm Green Flame"
        case .poltergeistCleaner: "Unlocks 🌀 Super-Vortex (+35% Radius)"
        case .swifferPro: "Unlocks 🔮 Spectral Violet Flame"
        case .grandSorcererBroom: "Unlocks 🪄 Enchanted Wide Swiffer (+35%)"
        case .hurricaneMaster: "Unlocks ❄️ Frostbite Cyan Flame"
        case .pumpkinDemolisher: "Unlocks 💥 Triple Gold Pumpkin Pop"
        case .midnightWatcher: "Unlocks 🌈 Prismatic Rainbow Flame"
        case .halloweenLord: "Unlocks 🏆 3× Permanent Gold Rain"
        default: nil
        }
    }
}

final class AchievementsManager {
    static let shared = AchievementsManager()

    private let defaults = UserDefaults.standard
    private let unlockedKey = "spookhush.unlockedAchievements"
    private let goldenCountKey = "spookhush.goldenLeaves"
    private let bestComboKey = "spookhush.bestGoldenCombo"
    private let vacuumedCountKey = "spookhush.vacuumedLeaves"
    private let sweptCountKey = "spookhush.sweptLeaves"
    private let blownCountKey = "spookhush.blownLeaves"
    private let windowDroppedKey = "spookhush.windowDroppedLeaves"
    private let pumpkinsCountKey = "spookhush.pumpkinsSmashed"
    private let activeSecondsKey = "spookhush.activeSeconds"

    private(set) var unlocked: Set<String>
    private(set) var goldenLeaves: Int
    private(set) var bestCombo: Int
    private(set) var currentCombo: Int = 0
    private var lastGoldenCatchTime: CFTimeInterval = -100
    private(set) var goldenFeverUntil: CFTimeInterval = 0

    private(set) var vacuumedLeaves: Float
    private(set) var sweptLeaves: Float
    private(set) var blownLeaves: Float
    private(set) var windowDroppedLeaves: Float
    private(set) var pumpkinsSmashed: Int
    private(set) var activeSeconds: Float

    private struct ToastItem {
        var icon: String
        var kicker: String
        var title: String
        var subtitle: String
        var progressFraction: CGFloat = 1.0
        var isUnlock: Bool = true
    }

    private var toastWindow: NSWindow?
    private var toastQueue: [ToastItem] = []
    private var showingToast = false
    private var panelWindow: NSWindow?
    var onUpdate: (() -> Void)?
    var onTrophyCelebration: (() -> Void)?

    private init() {
        let saved = defaults.stringArray(forKey: unlockedKey) ?? []
        unlocked = Set(saved)
        goldenLeaves = defaults.integer(forKey: goldenCountKey)
        bestCombo = max(1, defaults.integer(forKey: bestComboKey))
        vacuumedLeaves = defaults.float(forKey: vacuumedCountKey)
        sweptLeaves = defaults.float(forKey: sweptCountKey)
        blownLeaves = defaults.float(forKey: blownCountKey)
        windowDroppedLeaves = defaults.float(forKey: windowDroppedKey)
        pumpkinsSmashed = defaults.integer(forKey: pumpkinsCountKey)
        activeSeconds = defaults.float(forKey: activeSecondsKey)
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
        case .hellfireCrimson: isUnlocked(.dragonsHoard)
        case .frostbiteCyan: isUnlocked(.hurricaneMaster)
        case .prismaticRainbow: isUnlocked(.midnightWatcher)
        }
    }

    var isGoldenFeverActive: Bool {
        CACurrentMediaTime() < goldenFeverUntil
    }

    var goldenSpawnMultiplier: Float {
        var mult: Float = isUnlocked(.halloweenLord) ? 3.0 : (isUnlocked(.goldenHoarder) ? 1.5 : 1.0)
        if isGoldenFeverActive {
            mult *= 4.5
        }
        return mult
    }

    var vacuumRadiusMultiplier: Float {
        isUnlocked(.poltergeistCleaner) ? 1.35 : 1.0
    }

    var swifferRadiusMultiplier: Float {
        isUnlocked(.grandSorcererBroom) ? 1.35 : 1.0
    }

    var cornerPumpkinGoldPopCount: Int {
        isUnlocked(.pumpkinDemolisher) ? 3 : 1
    }

    var hasGoldenCursorTrail: Bool {
        isUnlocked(.autumnAlchemist)
    }

    var unlockedCount: Int { unlocked.count }
    var totalCount: Int { AchievementID.allCases.count }
    var goldenLeavesCollected: Int { goldenLeaves }

    func progress(for id: AchievementID) -> (current: Int, target: Int) {
        switch id {
        case .firstRustle:
            return (min(1, isUnlocked(.firstRustle) || sweptLeaves + vacuumedLeaves + blownLeaves > 0 ? 1 : 0), 1)
        case .goldSeeker:
            return (min(1, goldenLeaves), 1)
        case .goldenHoarder:
            return (min(25, goldenLeaves), 25)
        case .autumnAlchemist:
            return (min(100, goldenLeaves), 100)
        case .dragonsHoard:
            return (min(500, goldenLeaves), 500)
        case .comboHunter:
            return (min(5, bestCombo), 5)
        case .ghostBuster:
            return (min(1000, Int(vacuumedLeaves)), 1000)
        case .poltergeistCleaner:
            return (min(10000, Int(vacuumedLeaves)), 10000)
        case .swifferPro:
            return (min(2000, Int(sweptLeaves)), 2000)
        case .grandSorcererBroom:
            return (min(15000, Int(sweptLeaves)), 15000)
        case .hurricaneMaster:
            return (min(5000, Int(blownLeaves)), 5000)
        case .pumpkinSmasher:
            return (min(50, pumpkinsSmashed), 50)
        case .pumpkinDemolisher:
            return (min(250, pumpkinsSmashed), 250)
        case .hauntedArchitect:
            return (min(2500, Int(windowDroppedLeaves)), 2500)
        case .midnightWatcher:
            return (min(180, Int(activeSeconds / 60.0)), 180)
        case .halloweenLord:
            let others = AchievementID.allCases.filter { $0 != .halloweenLord }
            let done = others.filter { isUnlocked($0) }.count
            return (done, others.count)
        }
    }

    // MARK: - Event Recording

    func recordActiveTime(dt: Float) {
        let prevMinutes = Int(activeSeconds / 60.0)
        activeSeconds += dt
        let newMinutes = Int(activeSeconds / 60.0)
        if newMinutes > prevMinutes {
            defaults.set(activeSeconds, forKey: activeSecondsKey)
            checkMilestone(.midnightWatcher, prev: prevMinutes, curr: newMinutes, target: 180)
            if newMinutes >= 180 {
                check(.midnightWatcher)
            }
        }
    }

    func recordFirstRustle() {
        check(.firstRustle)
    }

    func recordGoldenLeaf(isBloodMoon: Bool = false) {
        let now = CACurrentMediaTime()
        if now - lastGoldenCatchTime <= 12.0 {
            currentCombo += 1
        } else {
            currentCombo = 1
        }
        lastGoldenCatchTime = now
        if currentCombo > bestCombo {
            bestCombo = currentCombo
            defaults.set(bestCombo, forKey: bestComboKey)
        }

        let prevGold = goldenLeaves
        let bonus = isBloodMoon ? 5 : (currentCombo >= 5 ? 3 : (currentCombo >= 3 ? 2 : 1))
        goldenLeaves += bonus
        defaults.set(goldenLeaves, forKey: goldenCountKey)

        if isBloodMoon || currentCombo == 5 {
            let duration: CFTimeInterval = isUnlocked(.comboHunter) ? 20.0 : 11.0
            goldenFeverUntil = max(now, goldenFeverUntil) + duration
            DispatchQueue.main.async {
                self.enqueueCustomToast(
                    icon: isBloodMoon ? "🩸" : "⚡",
                    kicker: isBloodMoon ? "BLOOD-MOON LEAF CAUGHT!" : "GOLDEN COMBO ×\(self.currentCombo)!",
                    title: "🔥 GOLDEN FEVER ACTIVATED (\(Int(duration))s)",
                    subtitle: "4.5× Golden Leaves raining from the sky! (+\(bonus) ✨)",
                    progressFraction: 1.0,
                    isUnlock: true
                )
            }
        }

        check(.goldSeeker)
        if currentCombo >= 5 { check(.comboHunter) }
        checkMilestone(.goldenHoarder, prev: prevGold, curr: goldenLeaves, target: 25)
        checkMilestone(.autumnAlchemist, prev: prevGold, curr: goldenLeaves, target: 100)
        checkMilestone(.dragonsHoard, prev: prevGold, curr: goldenLeaves, target: 500)
        if goldenLeaves >= 25 { check(.goldenHoarder) }
        if goldenLeaves >= 100 { check(.autumnAlchemist) }
        if goldenLeaves >= 500 { check(.dragonsHoard) }
        notifyPanel()
    }

    func recordVacuumed(_ count: Int) {
        recordVacuumed(amount: Float(count))
    }

    func recordVacuumed(amount: Float) {
        guard amount > 0 else { return }
        let prev = Int(vacuumedLeaves)
        vacuumedLeaves += amount
        let curr = Int(vacuumedLeaves)
        defaults.set(vacuumedLeaves, forKey: vacuumedCountKey)
        check(.firstRustle)
        checkMilestone(.ghostBuster, prev: prev, curr: curr, target: 1000)
        checkMilestone(.poltergeistCleaner, prev: prev, curr: curr, target: 10000)
        if vacuumedLeaves >= 1000 { check(.ghostBuster) }
        if vacuumedLeaves >= 10000 { check(.poltergeistCleaner) }
    }

    func recordSwept(_ count: Int) {
        recordSwept(amount: Float(count))
    }

    func recordSwept(amount: Float) {
        guard amount > 0 else { return }
        let prev = Int(sweptLeaves)
        sweptLeaves += amount
        let curr = Int(sweptLeaves)
        defaults.set(sweptLeaves, forKey: sweptCountKey)
        check(.firstRustle)
        checkMilestone(.swifferPro, prev: prev, curr: curr, target: 2000)
        checkMilestone(.grandSorcererBroom, prev: prev, curr: curr, target: 15000)
        if sweptLeaves >= 2000 { check(.swifferPro) }
        if sweptLeaves >= 15000 { check(.grandSorcererBroom) }
    }

    func recordBlown(_ count: Int) {
        guard count > 0 else { return }
        let prev = Int(blownLeaves)
        blownLeaves += Float(count)
        let curr = Int(blownLeaves)
        defaults.set(blownLeaves, forKey: blownCountKey)
        check(.firstRustle)
        checkMilestone(.hurricaneMaster, prev: prev, curr: curr, target: 5000)
        if blownLeaves >= 5000 { check(.hurricaneMaster) }
    }

    func recordWindowShed(amount: Float) {
        guard amount > 0 else { return }
        let prev = Int(windowDroppedLeaves)
        windowDroppedLeaves += amount
        let curr = Int(windowDroppedLeaves)
        defaults.set(windowDroppedLeaves, forKey: windowDroppedKey)
        checkMilestone(.hauntedArchitect, prev: prev, curr: curr, target: 2500)
        if windowDroppedLeaves >= 2500 { check(.hauntedArchitect) }
    }

    func recordPumpkinInteraction() {
        let prev = pumpkinsSmashed
        pumpkinsSmashed += 1
        defaults.set(pumpkinsSmashed, forKey: pumpkinsCountKey)
        checkMilestone(.pumpkinSmasher, prev: prev, curr: pumpkinsSmashed, target: 50)
        checkMilestone(.pumpkinDemolisher, prev: prev, curr: pumpkinsSmashed, target: 250)
        if pumpkinsSmashed >= 50 { check(.pumpkinSmasher) }
        if pumpkinsSmashed >= 250 { check(.pumpkinDemolisher) }
        notifyPanel()
    }

    func recordGust() {
        recordBlown(180)
        notifyPanel()
    }

    private func checkMilestone(_ id: AchievementID, prev: Int, curr: Int, target: Int) {
        guard !isUnlocked(id), curr < target, prev < curr else { return }
        for pct in [25, 50, 75] {
            let threshold = max(1, (target * pct) / 100)
            if prev < threshold && curr >= threshold {
                DispatchQueue.main.async {
                    self.enqueueCustomToast(
                        icon: id.icon,
                        kicker: "📈 TROPHY PROGRESS · \(pct)% (\(curr)/\(target))",
                        title: id.title,
                        subtitle: id.detail,
                        progressFraction: CGFloat(curr) / CGFloat(target),
                        isUnlock: false
                    )
                }
                break
            }
        }
    }

    private func check(_ id: AchievementID) {
        guard !isUnlocked(id) else { return }
        unlocked.insert(id.rawValue)
        defaults.set(Array(unlocked), forKey: unlockedKey)
        SoundEngine.shared.noteAchievementUnlocked()
        DispatchQueue.main.async {
            self.onTrophyCelebration?()
            self.enqueueCustomToast(
                icon: id.icon,
                kicker: "🏆 TROPHY UNLOCKED! · \(self.unlockedCount)/\(self.totalCount)",
                title: id.title,
                subtitle: id.rewardText ?? id.detail,
                progressFraction: 1.0,
                isUnlock: true
            )
            self.notifyPanel()
        }

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

    // MARK: - Floating Achievement & Jackpot Toast Banner

    private func enqueueCustomToast(
        icon: String,
        kicker: String,
        title: String,
        subtitle: String,
        progressFraction: CGFloat = 1.0,
        isUnlock: Bool = true
    ) {
        toastQueue.append(ToastItem(
            icon: icon,
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            progressFraction: progressFraction,
            isUnlock: isUnlock
        ))
        showNextToastIfNeeded()
    }

    private func showNextToastIfNeeded() {
        guard !showingToast, !toastQueue.isEmpty else { return }
        showingToast = true
        let item = toastQueue.removeFirst()

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            showingToast = false
            return
        }

        let width: CGFloat = 460
        let height: CGFloat = 102
        let frame = screen.visibleFrame
        let targetOrigin = CGPoint(x: frame.midX - width / 2, y: frame.maxY - height - 16)
        let startOrigin = CGPoint(x: targetOrigin.x, y: frame.maxY + 26)

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
        card.layer?.backgroundColor = NSColor(srgbRed: 0.09, green: 0.04, blue: 0.14, alpha: 0.97).cgColor
        card.layer?.cornerRadius = 18
        card.layer?.borderWidth = item.isUnlock ? 2.2 : 1.5
        card.layer?.borderColor = item.isUnlock
            ? NSColor(srgbRed: 1.0, green: 0.82, blue: 0.22, alpha: 0.96).cgColor
            : NSColor(srgbRed: 0.96, green: 0.62, blue: 0.20, alpha: 0.82).cgColor

        // 24k Gold Medal Emblem Box on Left
        let medalBox = NSView(frame: CGRect(x: 16, y: (height - 62) / 2 + 4, width: 62, height: 62))
        medalBox.wantsLayer = true
        medalBox.layer?.backgroundColor = item.isUnlock
            ? NSColor(srgbRed: 0.28, green: 0.17, blue: 0.05, alpha: 1.0).cgColor
            : NSColor(srgbRed: 0.18, green: 0.10, blue: 0.22, alpha: 1.0).cgColor
        medalBox.layer?.cornerRadius = 15
        medalBox.layer?.borderWidth = 1.6
        medalBox.layer?.borderColor = NSColor(srgbRed: 1.0, green: 0.84, blue: 0.28, alpha: 0.92).cgColor
        card.addSubview(medalBox)

        let badge = NSTextField(labelWithString: item.icon)
        badge.font = .systemFont(ofSize: 34)
        badge.alignment = .center
        badge.frame = CGRect(x: 4, y: 10, width: 54, height: 42)
        medalBox.addSubview(badge)

        if item.isUnlock {
            let starTop = NSTextField(labelWithString: "✦")
            starTop.font = .systemFont(ofSize: 14, weight: .bold)
            starTop.textColor = NSColor(srgbRed: 1.0, green: 0.92, blue: 0.38, alpha: 1.0)
            starTop.frame = CGRect(x: 66, y: height - 26, width: 18, height: 18)
            card.addSubview(starTop)
        }

        let textX: CGFloat = 90
        let textW: CGFloat = width - textX - 18

        let kicker = NSTextField(labelWithString: item.kicker)
        kicker.font = .systemFont(ofSize: 11, weight: .heavy)
        kicker.textColor = item.isUnlock
            ? NSColor(srgbRed: 1.0, green: 0.84, blue: 0.26, alpha: 1.0)
            : NSColor(srgbRed: 0.98, green: 0.68, blue: 0.28, alpha: 1.0)
        kicker.frame = CGRect(x: textX, y: height - 27, width: textW, height: 15)
        card.addSubview(kicker)

        let titleLabel = NSTextField(labelWithString: item.title)
        titleLabel.font = .systemFont(ofSize: 16.5, weight: .bold)
        titleLabel.textColor = NSColor(srgbRed: 1.0, green: 0.96, blue: 0.88, alpha: 1.0)
        titleLabel.frame = CGRect(x: textX, y: height - 50, width: textW, height: 22)
        card.addSubview(titleLabel)

        let subLabel = NSTextField(labelWithString: item.subtitle)
        subLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        subLabel.textColor = item.isUnlock
            ? NSColor(srgbRed: 0.46, green: 0.98, blue: 0.62, alpha: 1.0)
            : NSColor(srgbRed: 0.86, green: 0.78, blue: 0.90, alpha: 0.95)
        subLabel.frame = CGRect(x: textX, y: 24, width: textW, height: 18)
        card.addSubview(subLabel)

        // Animated Progress Bar inside Popup
        let barTrackWidth = width - 32
        let barBg = NSView(frame: CGRect(x: 16, y: 10, width: barTrackWidth, height: 6))
        barBg.wantsLayer = true
        barBg.layer?.backgroundColor = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.14).cgColor
        barBg.layer?.cornerRadius = 3
        card.addSubview(barBg)

        let barFill = NSView(frame: CGRect(x: 16, y: 10, width: 4, height: 6))
        barFill.wantsLayer = true
        barFill.layer?.backgroundColor = item.isUnlock
            ? NSColor(srgbRed: 1.0, green: 0.84, blue: 0.22, alpha: 1.0).cgColor
            : NSColor(srgbRed: 0.45, green: 0.95, blue: 0.60, alpha: 1.0).cgColor
        barFill.layer?.cornerRadius = 3
        card.addSubview(barFill)

        window.contentView = card
        window.alphaValue = 0
        window.orderFrontRegardless()
        self.toastWindow = window

        let finalBarWidth = max(12, barTrackWidth * min(1.0, max(0.05, item.progressFraction)))
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.42
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrameOrigin(targetOrigin)
            window.animator().alphaValue = 1
            barFill.animator().frame = CGRect(x: 16, y: 10, width: finalBarWidth, height: 6)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) { [weak self] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.32
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

    // MARK: - Trophies & Golden Leaves Window (16 Trophies + 2 Columns + Progress Bars)

    func showAchievementsWindow() {
        if let existing = panelWindow {
            rebuildPanelContent()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let width: CGFloat = 780
        let height: CGFloat = 650
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
        window.title = "Spookhush Trophies & 24k Golden Leaves"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(srgbRed: 0.08, green: 0.04, blue: 0.11, alpha: 1.0)
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.panelWindow = window

        rebuildPanelContent()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func rebuildPanelContent() {
        guard let window = panelWindow else { return }
        let width: CGFloat = 780
        let height: CGFloat = 650
        let root = NSView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(srgbRed: 0.08, green: 0.04, blue: 0.11, alpha: 1.0).cgColor

        // Header
        let headerTitle = NSTextField(labelWithString: "🎃 SPOOKHUSH TROPHIES (\(unlockedCount)/\(totalCount))")
        headerTitle.font = .systemFont(ofSize: 20, weight: .heavy)
        headerTitle.textColor = NSColor(srgbRed: 1.0, green: 0.66, blue: 0.18, alpha: 1.0)
        headerTitle.frame = CGRect(x: 24, y: height - 50, width: 320, height: 28)
        root.addSubview(headerTitle)

        // Test / Preview Trophy Popup Button
        let demoBtn = NSButton(frame: CGRect(x: 342, y: height - 51, width: 108, height: 28))
        demoBtn.bezelStyle = .rounded
        demoBtn.title = "🔔 Test Popup"
        demoBtn.font = .systemFont(ofSize: 11, weight: .bold)
        demoBtn.target = self
        demoBtn.action = #selector(triggerDemoPopup)
        root.addSubview(demoBtn)

        // Stats Summary Pill
        let goldPill = NSView(frame: CGRect(x: width - 318, y: height - 54, width: 298, height: 34))
        goldPill.wantsLayer = true
        goldPill.layer?.backgroundColor = NSColor(srgbRed: 0.22, green: 0.14, blue: 0.05, alpha: 1.0).cgColor
        goldPill.layer?.cornerRadius = 17
        goldPill.layer?.borderWidth = 1.2
        goldPill.layer?.borderColor = NSColor(srgbRed: 1.0, green: 0.82, blue: 0.24, alpha: 0.85).cgColor

        let statsString = "✨ \(goldenLeaves) Gold · ⚡ ×\(bestCombo) · 🎃 \(pumpkinsSmashed)"
        let goldLabel = NSTextField(labelWithString: statsString)
        goldLabel.font = .systemFont(ofSize: 12, weight: .bold)
        goldLabel.textColor = NSColor(srgbRed: 1.0, green: 0.88, blue: 0.30, alpha: 1.0)
        goldLabel.alignment = .center
        goldLabel.frame = CGRect(x: 8, y: 7, width: 282, height: 19)
        goldPill.addSubview(goldLabel)
        root.addSubview(goldPill)

        // 2-Column Grid of 16 Trophies (8 rows × 2 columns)
        let all = AchievementID.allCases
        let colWidth: CGFloat = (width - 56) / 2
        let rowHeight: CGFloat = 58
        let startY: CGFloat = height - 122

        for (index, id) in all.enumerated() {
            let col = index % 2
            let rowIdx = index / 2
            let x: CGFloat = 20 + CGFloat(col) * (colWidth + 16)
            let y: CGFloat = startY - CGFloat(rowIdx) * (rowHeight + 6)

            let done = isUnlocked(id)
            let prog = progress(for: id)
            let fraction = min(1.0, max(0.0, CGFloat(prog.current) / CGFloat(max(1, prog.target))))

            let card = NSView(frame: CGRect(x: x, y: y, width: colWidth, height: rowHeight))
            card.wantsLayer = true
            card.layer?.backgroundColor = done
                ? NSColor(srgbRed: 0.19, green: 0.11, blue: 0.24, alpha: 0.96).cgColor
                : NSColor(srgbRed: 0.12, green: 0.07, blue: 0.16, alpha: 0.80).cgColor
            card.layer?.cornerRadius = 10
            card.layer?.borderWidth = 1.2
            card.layer?.borderColor = done
                ? NSColor(srgbRed: 1.0, green: 0.74, blue: 0.22, alpha: 0.78).cgColor
                : NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.08).cgColor

            // Progress bar along the bottom of the card
            let barBg = NSView(frame: CGRect(x: 10, y: 5, width: colWidth - 20, height: 4))
            barBg.wantsLayer = true
            barBg.layer?.backgroundColor = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10).cgColor
            barBg.layer?.cornerRadius = 2
            card.addSubview(barBg)

            let barFill = NSView(frame: CGRect(x: 10, y: 5, width: (colWidth - 20) * (done ? 1.0 : fraction), height: 4))
            barFill.wantsLayer = true
            barFill.layer?.backgroundColor = done
                ? NSColor(srgbRed: 0.42, green: 0.96, blue: 0.58, alpha: 1.0).cgColor
                : NSColor(srgbRed: 1.0, green: 0.72, blue: 0.20, alpha: 0.95).cgColor
            barFill.layer?.cornerRadius = 2
            card.addSubview(barFill)

            let iconField = NSTextField(labelWithString: done ? id.icon : "🔒")
            iconField.font = .systemFont(ofSize: 22)
            iconField.frame = CGRect(x: 10, y: 16, width: 32, height: 30)
            card.addSubview(iconField)

            let nameField = NSTextField(labelWithString: id.title)
            nameField.font = .systemFont(ofSize: 12.5, weight: .bold)
            nameField.textColor = done
                ? NSColor(srgbRed: 1.0, green: 0.94, blue: 0.84, alpha: 1.0)
                : NSColor(srgbRed: 0.78, green: 0.72, blue: 0.82, alpha: 1.0)
            nameField.frame = CGRect(x: 42, y: 34, width: colWidth - 150, height: 17)
            card.addSubview(nameField)

            let subText = id.rewardText ?? id.detail
            let descField = NSTextField(labelWithString: done && id.rewardText != nil ? "★ \(subText)" : id.detail)
            descField.font = .systemFont(ofSize: 10.5, weight: done && id.rewardText != nil ? .semibold : .regular)
            descField.textColor = (done && id.rewardText != nil)
                ? NSColor(srgbRed: 1.0, green: 0.82, blue: 0.32, alpha: 0.95)
                : NSColor(srgbRed: 0.76, green: 0.68, blue: 0.65, alpha: 0.9)
            descField.frame = CGRect(x: 42, y: 14, width: colWidth - 78, height: 16)
            card.addSubview(descField)

            let statusText = done ? "UNLOCKED ✓" : "\(prog.current)/\(prog.target)"
            let statusField = NSTextField(labelWithString: statusText)
            statusField.font = .systemFont(ofSize: 10.5, weight: .bold)
            statusField.alignment = .right
            statusField.textColor = done
                ? NSColor(srgbRed: 0.45, green: 0.96, blue: 0.58, alpha: 1.0)
                : NSColor(srgbRed: 0.98, green: 0.70, blue: 0.28, alpha: 0.95)
            statusField.frame = CGRect(x: colWidth - 118, y: 34, width: 82, height: 16)
            card.addSubview(statusField)

            // Mini Popup Preview Button on each card
            let popBtn = NSButton(frame: CGRect(x: colWidth - 32, y: 20, width: 24, height: 24))
            popBtn.bezelStyle = .rounded
            popBtn.isBordered = false
            popBtn.title = "🔔"
            popBtn.toolTip = "Preview Trophy Popup"
            popBtn.font = .systemFont(ofSize: 12)
            popBtn.tag = index
            popBtn.target = self
            popBtn.action = #selector(previewCardPopup(_:))
            card.addSubview(popBtn)

            root.addSubview(card)
        }

        // Footer: 7 Lantern & Pumpkin Flame Colors
        let flameTitle = NSTextField(labelWithString: "LANTERN & CORNER JACK-O'-LANTERN FLAME COLOR (UNLOCKED BY TROPHIES):")
        flameTitle.font = .systemFont(ofSize: 10.5, weight: .bold)
        flameTitle.textColor = NSColor(srgbRed: 0.88, green: 0.78, blue: 0.70, alpha: 0.9)
        flameTitle.frame = CGRect(x: 22, y: 46, width: width - 44, height: 15)
        root.addSubview(flameTitle)

        var bx: CGFloat = 20
        let btnW: CGFloat = 102
        for theme in FlameTheme.allCases {
            let unlockedTheme = isFlameUnlocked(theme)
            let isSelected = Preferences.flameTheme == theme
            let btn = NSButton(frame: CGRect(x: bx, y: 12, width: btnW, height: 28))
            btn.bezelStyle = .rounded
            btn.title = unlockedTheme ? (isSelected ? "✓ \(theme.title)" : theme.title) : "🔒 \(theme.title)"
            btn.font = .systemFont(ofSize: 10.5, weight: isSelected ? .bold : .regular)
            btn.isEnabled = unlockedTheme
            btn.tag = theme.rawValue
            btn.target = self
            btn.action = #selector(selectFlameTheme(_:))
            root.addSubview(btn)
            bx += btnW + 6
        }

        window.contentView = root
    }

    @objc private func triggerDemoPopup() {
        let unlockedList = AchievementID.allCases.filter { isUnlocked($0) }
        let pick = unlockedList.randomElement() ?? .goldenHoarder
        showPopup(for: pick)
    }

    @objc private func previewCardPopup(_ sender: NSButton) {
        let all = AchievementID.allCases
        guard sender.tag >= 0 && sender.tag < all.count else { return }
        showPopup(for: all[sender.tag])
    }

    func showPopup(for id: AchievementID) {
        let done = isUnlocked(id)
        let prog = progress(for: id)
        let frac = done ? 1.0 : max(0.08, CGFloat(prog.current) / CGFloat(max(1, prog.target)))
        SoundEngine.shared.noteAchievementUnlocked()
        onTrophyCelebration?()
        enqueueCustomToast(
            icon: id.icon,
            kicker: done
                ? "🏆 TROPHY UNLOCKED! · \(unlockedCount)/\(totalCount)"
                : "📈 TROPHY PROGRESS · \(prog.current)/\(prog.target)",
            title: id.title,
            subtitle: id.rewardText ?? id.detail,
            progressFraction: frac,
            isUnlock: done
        )
    }

    @objc private func selectFlameTheme(_ sender: NSButton) {
        guard let theme = FlameTheme(rawValue: sender.tag), isFlameUnlocked(theme) else { return }
        Preferences.flameTheme = theme
        SoundEngine.shared.noteGoldenCatch()
        rebuildPanelContent()
        onUpdate?()
    }
}
