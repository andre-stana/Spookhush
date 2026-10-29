import AppKit

final class OverlayWindow: NSWindow {
    private static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    /// Just under the Dock, so its icons stay in front as they grow under the pointer.
    static let belowDockLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) - 1)
    private static let lockScreenLevel = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)

    private let frontLevel: NSWindow.Level

    var behindWindows = false {
        didSet { updateLevel() }
    }

    var onLockedScreen = false {
        didSet { updateLevel() }
    }

    var showsInScreenshots = false {
        didSet { sharingType = showsInScreenshots ? .readOnly : .none }
    }

    init(screen: NSScreen, level: NSWindow.Level = .statusBar) {
        frontLevel = level
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        canBecomeVisibleWithoutLogin = true
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.level = level
        sharingType = .none
        setFrame(screen.frame, display: false)
    }

    private func updateLevel() {
        if onLockedScreen {
            level = Self.lockScreenLevel
            orderFrontRegardless()
        } else {
            level = behindWindows ? Self.desktopLevel : frontLevel
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Borderless windows are otherwise pushed below the menu bar.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
