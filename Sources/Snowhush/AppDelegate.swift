import AppKit
import MetalKit
import ServiceManagement
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SPUStandardUserDriverDelegate {
    private var device: MTLDevice!
    private var screens: [ScreenSnow] = []
    private var snowfall = Snowfall.steady
    private var accumulates = true
    private var thaws = true
    private var snowOnWindows = true
    private var behindWindows = false
    private var lanternLight = true
    private var cornerPumpkins = true
    private var cursorTool = CursorTool.lantern
    private var soundEffects = true
    private var snowfallHeld = false
    private var statusItem: NSStatusItem!
    private let snowfallSlider = SnowfallSlider()
    private var accumulateItem: NSMenuItem!
    private var meltItem: NSMenuItem!
    private var snowOnWindowsItem: NSMenuItem!
    private var clearItem: NSMenuItem!
    private var toolItems: [CursorTool: NSMenuItem] = [:]
    private var cornerPumpkinsItem: NSMenuItem!
    private var lanternItem: NSMenuItem!
    private var soundItem: NSMenuItem!
    private var trophiesItem: NSMenuItem!
    private var behindWindowsItem: NSMenuItem!
    private var screenshotsItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var observers: [NSObjectProtocol] = []
    private var screensAsleep = false
    private var screenLocked = false
    private var sessionInactive = false
    private var updater: SPUStandardUpdaterController!
    private var welcome: WelcomeController?
    private let power = PowerMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if AppMover.moveIfNeeded() {
            NSApp.terminate(nil)
            return
        }
        Preferences.registerDefaults()
        guard let device = MTLCreateSystemDefaultDevice() else {
            NSApp.terminate(nil)
            return
        }
        self.device = device
        snowfall = Preferences.snowfall
        accumulates = Preferences.accumulate
        thaws = Preferences.meltSnow
        snowOnWindows = Preferences.snowOnWindows
        behindWindows = Preferences.behindWindows
        lanternLight = Preferences.lanternLight
        cornerPumpkins = Preferences.cornerPumpkins
        cursorTool = Preferences.cursorTool
        soundEffects = Preferences.soundEffects
        SoundEngine.shared.isEnabled = soundEffects
        AchievementsManager.shared.onTrophyCelebration = { [weak self] in
            self?.screens.forEach { $0.simulation.triggerTrophyCelebration() }
        }
        snowfallHeld = !Preferences.welcomed
        syncScreens()
        guard !screens.isEmpty else {
            NSApp.terminate(nil)
            return
        }

        updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
        statusItem = makeStatusItem()
        updateStatusIcon()
        observeSystem()
        if snowfallHeld {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in self?.showWelcome() }
        }
    }

    var supportsGentleScheduledUpdateReminders: Bool { true }

    // MARK: - Displays

    private func syncScreens() {
        let current = NSScreen.screens
        let ids = Set(current.compactMap(\.displayID))
        for gone in screens where !ids.contains(gone.displayID) { gone.close() }
        screens.removeAll { !ids.contains($0.displayID) }

        for screen in current {
            if let existing = screens.first(where: { $0.displayID == screen.displayID }) {
                existing.fit(to: screen)
            } else if let snow = ScreenSnow(screen: screen, device: device, snowOnWindows: { [unowned self] in snowOnWindows }) {
                snow.simulation.snowfallHeld = snowfallHeld
                snow.simulation.snowfallReleased = { [weak self] in self?.releaseSnowfall() }
                snow.apply(power.budget)
                screens.append(snow)
            }
        }
        updateActivity()
    }

    private func releaseSnowfall() {
        snowfallHeld = false
        for snow in screens { snow.simulation.snowfallHeld = false }
    }

    private func showWelcome() {
        let welcome = WelcomeController()
        welcome.scatter = { [weak self] pieces in
            guard let self, let first = pieces.first else { return }
            let point = CGPoint(x: CGFloat(first.position.x), y: CGFloat(first.position.y))
            guard let snow = screens.first(where: { $0.window.frame.contains(point) }) ?? screens.first else { return }
            let origin = SIMD2(Float(snow.window.frame.minX), Float(snow.window.frame.minY))
            SoundEngine.shared.noteGust()
            snow.simulation.scatter(pieces.map { piece in
                var local = piece
                local.position -= origin
                return local
            })
        }
        welcome.skipped = { [weak self] in self?.releaseSnowfall() }
        welcome.finished = { [weak self] in
            Preferences.welcomed = true
            self?.welcome = nil
        }
        self.welcome = welcome
        welcome.show()
    }

    // MARK: - Menu

    private static func makePumpkinMenuIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setFillColor(NSColor.black.cgColor)

            // Stem
            let stem = CGMutablePath()
            stem.move(to: CGPoint(x: 8.2, y: 13.8))
            stem.addQuadCurve(to: CGPoint(x: 10.6, y: 16.4), control: CGPoint(x: 8.8, y: 16.0))
            stem.addLine(to: CGPoint(x: 11.4, y: 15.6))
            stem.addQuadCurve(to: CGPoint(x: 9.8, y: 13.5), control: CGPoint(x: 10.2, y: 14.8))
            stem.closeSubpath()
            ctx.addPath(stem)
            ctx.fillPath()

            // Pumpkin body with carved cutouts using even-odd fill rule
            let body = CGMutablePath()
            body.addRoundedRect(in: CGRect(x: 2.0, y: 2.2, width: 14.0, height: 11.6), cornerWidth: 5.5, cornerHeight: 5.5)

            // Left eye (triangle)
            body.move(to: CGPoint(x: 5.0, y: 8.4))
            body.addLine(to: CGPoint(x: 6.5, y: 10.8))
            body.addLine(to: CGPoint(x: 7.8, y: 8.4))
            body.closeSubpath()

            // Right eye (triangle)
            body.move(to: CGPoint(x: 10.2, y: 8.4))
            body.addLine(to: CGPoint(x: 11.5, y: 10.8))
            body.addLine(to: CGPoint(x: 13.0, y: 8.4))
            body.closeSubpath()

            // Grin
            body.move(to: CGPoint(x: 4.8, y: 6.2))
            body.addQuadCurve(to: CGPoint(x: 13.2, y: 6.2), control: CGPoint(x: 9.0, y: 3.4))
            body.addQuadCurve(to: CGPoint(x: 4.8, y: 6.2), control: CGPoint(x: 9.0, y: 5.0))
            body.closeSubpath()

            ctx.addPath(body)
            ctx.fillPath(using: .evenOdd)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Spookhush"
        return image
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = Self.makePumpkinMenuIcon()

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        menu.addItem(.sectionHeader(title: "Autumn Fall"))
        snowfallSlider.changed = { [unowned self] in select($0) }
        let sliderItem = NSMenuItem()
        sliderItem.view = snowfallSlider
        menu.addItem(sliderItem)
        menu.addItem(.separator())
        accumulateItem = add("Accumulate", #selector(toggleAccumulate), to: menu)
        meltItem = add("Fade Leaves", #selector(toggleMeltSnow), to: menu)
        snowOnWindowsItem = add("Leaves on Windows", #selector(toggleSnowOnWindows), to: menu)
        clearItem = add("Clear Leaves", #selector(clearSnow), to: menu)
        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Cursor Tool"))
        for tool in CursorTool.allCases {
            let tItem = add(tool.title, #selector(selectCursorTool(_:)), to: menu)
            tItem.tag = tool.rawValue
            toolItems[tool] = tItem
        }
        menu.addItem(.separator())
        cornerPumpkinsItem = add("Corner Jack-o'-Lanterns", #selector(toggleCornerPumpkins), to: menu)
        lanternItem = add("Lantern Light", #selector(toggleLanternLight), to: menu)
        soundItem = add("Sound Effects", #selector(toggleSoundEffects), to: menu)
        trophiesItem = add("🏆 Trophies & Golden Leaves…", #selector(openTrophiesWindow), to: menu)
        menu.addItem(.separator())
        behindWindowsItem = add("Behind Windows", #selector(toggleBehindWindows), to: menu)
        screenshotsItem = add("Show in Screenshots", #selector(toggleScreenshots), to: menu)
        loginItem = add("Open at Login", #selector(toggleOpenAtLogin), to: menu)
        menu.addItem(.separator())
        let updates = menu.addItem(withTitle: "Check for Updates…", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "")
        updates.target = updater
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        item.menu = menu
        return item
    }

    @discardableResult
    private func add(_ title: String, _ action: Selector, to menu: NSMenu) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        snowfallSlider.snowfall = snowfall
        accumulateItem.state = accumulates ? .on : .off
        meltItem.state = thaws ? .on : .off
        meltItem.isEnabled = accumulates
        snowOnWindowsItem.state = snowOnWindows ? .on : .off
        snowOnWindowsItem.isEnabled = !behindWindows
        clearItem.isEnabled = screens.contains { $0.simulation.hasSnow || $0.simulation.spriteCount > 0 }
        for (tool, item) in toolItems {
            item.state = (tool == cursorTool) ? .on : .off
        }
        cornerPumpkinsItem.state = cornerPumpkins ? .on : .off
        lanternItem.state = lanternLight ? .on : .off
        soundItem.state = soundEffects ? .on : .off
        let ach = AchievementsManager.shared
        trophiesItem.title = "🏆 Trophies (\(ach.unlockedCount)/\(ach.totalCount)) · ✨ \(ach.goldenLeavesCollected) Gold…"
        behindWindowsItem.state = behindWindows ? .on : .off
        screenshotsItem.state = Preferences.showInScreenshots ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func select(_ snowfall: Snowfall) {
        self.snowfall = snowfall
        Preferences.snowfall = snowfall
        for snow in screens { snow.simulation.snowfall = snowfall }
        updateStatusIcon()
    }

    @objc private func toggleAccumulate() {
        accumulates.toggle()
        Preferences.accumulate = accumulates
        for snow in screens { snow.simulation.accumulates = accumulates }
    }

    @objc private func toggleMeltSnow() {
        thaws.toggle()
        Preferences.meltSnow = thaws
        for snow in screens { snow.simulation.thaws = thaws }
    }

    @objc private func toggleSnowOnWindows() {
        snowOnWindows.toggle()
        Preferences.snowOnWindows = snowOnWindows
        if !snowOnWindows { screens.forEach { $0.dropWindowSnow() } }
    }

    @objc private func clearSnow() {
        let direction = screens.first?.simulation.breezeDirection ?? -1
        let calm = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        for snow in screens { snow.simulation.blowAway(direction: direction, calm: calm) }
    }

    @objc private func toggleLanternLight() {
        lanternLight.toggle()
        Preferences.lanternLight = lanternLight
    }

    @objc private func toggleCornerPumpkins() {
        cornerPumpkins.toggle()
        Preferences.cornerPumpkins = cornerPumpkins
    }

    @objc private func selectCursorTool(_ sender: NSMenuItem) {
        guard let tool = CursorTool(rawValue: sender.tag) else { return }
        cursorTool = tool
        Preferences.cursorTool = tool
    }

    @objc private func openTrophiesWindow() {
        AchievementsManager.shared.showAchievementsWindow()
    }

    @objc private func toggleSoundEffects() {
        soundEffects.toggle()
        Preferences.soundEffects = soundEffects
        SoundEngine.shared.isEnabled = soundEffects
        if soundEffects {
            SoundEngine.shared.noteBurst(size: 9, force: 0.7, isPumpkin: true)
        }
    }

    @objc private func toggleBehindWindows() {
        behindWindows.toggle()
        Preferences.behindWindows = behindWindows
        for snow in screens {
            snow.window.behindWindows = behindWindows
            if behindWindows { snow.dropWindowSnow() }
        }
    }

    @objc private func toggleScreenshots() {
        Preferences.showInScreenshots.toggle()
        for snow in screens {
            snow.window.showsInScreenshots = Preferences.showInScreenshots
            snow.dock.window.showsInScreenshots = Preferences.showInScreenshots
        }
    }

    @objc private func toggleOpenAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Spookhush: login item change failed: \(error)")
        }
    }

    private func updateStatusIcon() {
        statusItem.button?.appearsDisabled = snowfall == .off
    }

    // MARK: - System

    private func observeSystem() {
        power.changed = { [unowned self] in screens.forEach { $0.apply(power.budget) } }
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()

        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.screensAsleep = true }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.screensAsleep = false }
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification) { $0.sessionInactive = true }
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { $0.sessionInactive = false }
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.screenLocked = true }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.screenLocked = false }
        observe(.default, NSWindow.didChangeOcclusionStateNotification) { _ in }
        observe(.default, NSApplication.didChangeScreenParametersNotification) { $0.syncScreens() }
        observe(workspace, NSWorkspace.activeSpaceDidChangeNotification) { $0.screens.forEach { $0.spaceChanged() } }
        observe(workspace, NSWorkspace.didActivateApplicationNotification) { $0.screens.forEach { $0.watchWindows() } }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        object: AnyObject? = nil,
        _ change: @escaping (AppDelegate) -> Void
    ) {
        observers.append(center.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            guard let self else { return }
            change(self)
            self.updateActivity()
        })
    }

    private func updateActivity() {
        let awake = !screensAsleep && !screenLocked && !sessionInactive
        for snow in screens {
            snow.setActive(awake && snow.window.occlusionState.contains(.visible))
        }
    }
}
