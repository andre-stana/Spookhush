import AppKit
import simd

enum Snowfall: Int, CaseIterable {
    case off, light, steady, heavy, variable

    var title: String {
        switch self {
        case .off: "Off"
        case .light: "Light"
        case .steady: "Steady"
        case .heavy: "Heavy"
        case .variable: "Variable"
        }
    }

    var flakesPerMegapoint: Float {
        switch self {
        case .off: 0
        case .light: 150
        case .steady: 380
        case .heavy: 800
        case .variable: 380
        }
    }
}

enum CursorTool: Int, CaseIterable {
    case lantern = 0
    case vacuum = 1
    case swiffer = 2
    case blower = 3
    case magnet = 4

    var title: String {
        switch self {
        case .lantern: "🎃 Lantern (Classic)"
        case .vacuum: "🌀 Ghost-Vac (Vacuum)"
        case .swiffer: "🧹 Witch Swiffer (Clean Sweep)"
        case .blower: "💨 Leaf Blower (Turbo Jet)"
        case .magnet: "🧲 Golden Magnet (Gold Attractor)"
        }
    }

    var shortName: String {
        switch self {
        case .lantern: "Lantern"
        case .vacuum: "Ghost-Vac"
        case .swiffer: "Witch Swiffer"
        case .blower: "Leaf Blower"
        case .magnet: "Golden Magnet"
        }
    }
}

enum FlameTheme: Int, CaseIterable {
    case classicAmber = 0
    case royalGold = 1
    case ectoplasmGreen = 2
    case spectralViolet = 3
    case hellfireCrimson = 4
    case frostbiteCyan = 5
    case prismaticRainbow = 6

    var title: String {
        switch self {
        case .classicAmber: "🕯️ Amber"
        case .royalGold: "👑 24k Gold"
        case .ectoplasmGreen: "👻 Ectoplasm"
        case .spectralViolet: "🔮 Spectral"
        case .hellfireCrimson: "🔥 Hellfire"
        case .frostbiteCyan: "❄️ Frostbite"
        case .prismaticRainbow: "🌈 Prismatic"
        }
    }

    func color(at time: Float = 0) -> SIMD3<Float> {
        switch self {
        case .classicAmber: return SIMD3(1.0, 0.54, 0.14)
        case .royalGold: return SIMD3(1.0, 0.88, 0.22)
        case .ectoplasmGreen: return SIMD3(0.22, 1.0, 0.48)
        case .spectralViolet: return SIMD3(0.82, 0.32, 1.0)
        case .hellfireCrimson: return SIMD3(1.0, 0.16, 0.22)
        case .frostbiteCyan: return SIMD3(0.24, 0.90, 1.0)
        case .prismaticRainbow:
            let r = 0.65 + 0.35 * sin(time * 2.2)
            let g = 0.65 + 0.35 * sin(time * 2.2 + 2.094)
            let b = 0.65 + 0.35 * sin(time * 2.2 + 4.188)
            return SIMD3(r, g, b)
        }
    }

    var color: SIMD3<Float> {
        color(at: Float(CACurrentMediaTime().truncatingRemainder(dividingBy: 100)))
    }
}

enum Preferences {
    private static let defaults = UserDefaults.standard
    private static let snowfallKey = "snowfall"
    private static let behindWindowsKey = "behindWindows"
    private static let meltSnowKey = "meltSnow"
    private static let accumulateKey = "accumulate"
    private static let snowOnWindowsKey = "snowOnWindows"
    private static let welcomedKey = "welcomed"
    private static let showInScreenshotsKey = "showInScreenshots"
    private static let lanternLightKey = "lanternLight"
    private static let soundEffectsKey = "soundEffects"
    private static let cornerPumpkinsKey = "cornerPumpkins"
    private static let cursorToolKey = "cursorTool"
    private static let flameThemeKey = "flameTheme"

    static func registerDefaults() {
        let calm = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        defaults.register(defaults: [
            snowfallKey: (calm ? Snowfall.light : .steady).rawValue,
            behindWindowsKey: false,
            meltSnowKey: true,
            accumulateKey: true,
            snowOnWindowsKey: true,
            showInScreenshotsKey: false,
            lanternLightKey: true,
            soundEffectsKey: true,
            cornerPumpkinsKey: true,
            cursorToolKey: CursorTool.lantern.rawValue,
            flameThemeKey: FlameTheme.classicAmber.rawValue,
        ])
    }

    static var snowfall: Snowfall {
        get { Snowfall(rawValue: defaults.integer(forKey: snowfallKey)) ?? .steady }
        set { defaults.set(newValue.rawValue, forKey: snowfallKey) }
    }

    static var snowOnWindows: Bool {
        get { defaults.bool(forKey: snowOnWindowsKey) }
        set { defaults.set(newValue, forKey: snowOnWindowsKey) }
    }

    static var accumulate: Bool {
        get { defaults.bool(forKey: accumulateKey) }
        set { defaults.set(newValue, forKey: accumulateKey) }
    }

    static var meltSnow: Bool {
        get { defaults.bool(forKey: meltSnowKey) }
        set { defaults.set(newValue, forKey: meltSnowKey) }
    }

    static var welcomed: Bool {
        get { defaults.bool(forKey: welcomedKey) }
        set { defaults.set(newValue, forKey: welcomedKey) }
    }

    static var behindWindows: Bool {
        get { defaults.bool(forKey: behindWindowsKey) }
        set { defaults.set(newValue, forKey: behindWindowsKey) }
    }

    static var showInScreenshots: Bool {
        get { defaults.bool(forKey: showInScreenshotsKey) }
        set { defaults.set(newValue, forKey: showInScreenshotsKey) }
    }

    static var lanternLight: Bool {
        get { defaults.bool(forKey: lanternLightKey) }
        set { defaults.set(newValue, forKey: lanternLightKey) }
    }

    static var soundEffects: Bool {
        get { defaults.bool(forKey: soundEffectsKey) }
        set { defaults.set(newValue, forKey: soundEffectsKey) }
    }

    static var cornerPumpkins: Bool {
        get { defaults.bool(forKey: cornerPumpkinsKey) }
        set { defaults.set(newValue, forKey: cornerPumpkinsKey) }
    }

    static var cursorTool: CursorTool {
        get { CursorTool(rawValue: defaults.integer(forKey: cursorToolKey)) ?? .lantern }
        set { defaults.set(newValue.rawValue, forKey: cursorToolKey) }
    }

    static var flameTheme: FlameTheme {
        get { FlameTheme(rawValue: defaults.integer(forKey: flameThemeKey)) ?? .classicAmber }
        set { defaults.set(newValue.rawValue, forKey: flameThemeKey) }
    }
}
