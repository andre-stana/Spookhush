use std::ffi::c_void;

use windows::Win32::Foundation::{ERROR_SUCCESS, WIN32_ERROR};
use windows::Win32::System::Registry::{
    HKEY_CURRENT_USER, REG_DWORD, REG_SZ, RRF_RT_REG_DWORD, RRF_RT_REG_SZ, RegDeleteKeyValueW, RegGetValueW, RegSetKeyValueW,
};
use windows::Win32::UI::WindowsAndMessaging::{SPI_GETCLIENTAREAANIMATION, SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS, SystemParametersInfoW};
use windows::core::{BOOL, PCWSTR, w};

use snowhush_core::simulation::{CursorTool, SimulationEvents, Snowfall};

const KEY: PCWSTR = w!("Software\\Snowhush");
const RUN: PCWSTR = w!("Software\\Microsoft\\Windows\\CurrentVersion\\Run");
const RUN_VALUE: PCWSTR = w!("Snowhush");

#[derive(Clone, Copy)]
pub struct Settings {
    pub snowfall: Snowfall,
    pub accumulate: bool,
    pub melt: bool,
    pub snow_on_windows: bool,
    pub behind_windows: bool,
    pub show_in_screenshots: bool,
    pub welcomed: bool,
    pub classic_mode: bool,
    pub cursor_tool: CursorTool,
    pub corner_pumpkins: bool,
}

impl Settings {
    pub fn load() -> Settings {
        let calm = !animations_enabled();
        let snowfall = read(w!("snowfall")).and_then(|i| Snowfall::ALL.get(i as usize).copied());
        let cursor_tool = read(w!("cursorTool")).and_then(|i| CursorTool::ALL.get(i as usize).copied());
        Settings {
            snowfall: snowfall.unwrap_or(if calm { Snowfall::Light } else { Snowfall::Steady }),
            accumulate: read(w!("accumulate")).is_none_or(|v| v != 0),
            melt: read(w!("meltSnow")).is_none_or(|v| v != 0),
            snow_on_windows: read(w!("snowOnWindows")).is_none_or(|v| v != 0),
            behind_windows: read(w!("behindWindows")).is_some_and(|v| v != 0),
            show_in_screenshots: read(w!("showInScreenshots")).is_some_and(|v| v != 0),
            welcomed: read(w!("welcomed")).is_some_and(|v| v != 0),
            classic_mode: read(w!("classicMode")).is_none_or(|v| v != 0),
            cursor_tool: cursor_tool.unwrap_or(CursorTool::Lantern),
            corner_pumpkins: read(w!("cornerPumpkins")).is_none_or(|v| v != 0),
        }
    }

    pub fn save(&self) {
        let snowfall = Snowfall::ALL.iter().position(|&s| s == self.snowfall).unwrap_or(2);
        let cursor_tool = CursorTool::ALL.iter().position(|&t| t == self.cursor_tool).unwrap_or(0);
        write(w!("snowfall"), snowfall as u32);
        write(w!("accumulate"), self.accumulate as u32);
        write(w!("meltSnow"), self.melt as u32);
        write(w!("snowOnWindows"), self.snow_on_windows as u32);
        write(w!("behindWindows"), self.behind_windows as u32);
        write(w!("showInScreenshots"), self.show_in_screenshots as u32);
        write(w!("welcomed"), self.welcomed as u32);
        write(w!("classicMode"), self.classic_mode as u32);
        write(w!("cursorTool"), cursor_tool as u32);
        write(w!("cornerPumpkins"), self.corner_pumpkins as u32);
    }
}

pub struct TrophyInfo {
    pub bit: u32,
    pub icon: &'static str,
    pub title: &'static str,
    pub description: &'static str,
    pub reward: &'static str,
}

pub const TROPHIES: [TrophyInfo; 16] = [
    TrophyInfo { bit: 0, icon: "🍂", title: "Autumn Awakening", description: "Rustle falling Halloween leaves with your cursor.", reward: "+10% Golden Leaf luck" },
    TrophyInfo { bit: 1, icon: "✨", title: "Golden Seeker", description: "Catch your very first rare 24k Golden Leaf in mid-air.", reward: "Golden Sparkle Burst" },
    TrophyInfo { bit: 2, icon: "🏅", title: "Golden Collector (15)", description: "Catch 15 rare Golden Leaves.", reward: "+35% Golden Leaf spawn rate" },
    TrophyInfo { bit: 3, icon: "👑", title: "24k Midas Touch (75)", description: "Catch 75 rare Golden Leaves.", reward: "+80% Golden Leaf spawn rate" },
    TrophyInfo { bit: 4, icon: "🏛️", title: "Golden Dynasty (250)", description: "Catch 250 rare Golden Leaves.", reward: "+135% Golden Leaf spawn rate" },
    TrophyInfo { bit: 5, icon: "🐉", title: "24k Sovereign (1,000)", description: "Catch 1,000 Golden Leaves across your sessions.", reward: "+220% Golden Leaf spawn rate" },
    TrophyInfo { bit: 6, icon: "🩸", title: "Blood-Moon Hunter", description: "Catch a Mythic Blood-Moon Jackpot Leaf (+5 Golden value).", reward: "Unlocks Crimson-Gold Aura" },
    TrophyInfo { bit: 7, icon: "⚡", title: "Golden Combo Master (5x)", description: "Catch 5 Golden Leaves within 25 seconds of each other.", reward: "Golden Fever Boost" },
    TrophyInfo { bit: 8, icon: "👻", title: "Ghost-Vac Apprentice (500)", description: "Suck up 500 leaves using the Ghost-Vac.", reward: "Supercharged Suction" },
    TrophyInfo { bit: 9, icon: "🌀", title: "Poltergeist Exterminator (5,000)", description: "Suck up 5,000 leaves using the Ghost-Vac.", reward: "Abyssal Vortex Core" },
    TrophyInfo { bit: 10, icon: "🧹", title: "Swiffer Sweeper (1,000)", description: "Sweep 1,000 settled pile leaves with the Magic Swiffer.", reward: "Golden Bristle Trail" },
    TrophyInfo { bit: 11, icon: "🧙", title: "Grand Witch Sweeper (10,000)", description: "Sweep 10,000 settled pile leaves with the Magic Swiffer.", reward: "Enchanted Broom Mastery" },
    TrophyInfo { bit: 12, icon: "💨", title: "Hurricane Master (2,500)", description: "Blast 2,500 leaves with the Gust Blower.", reward: "Gale-Force Turbulence" },
    TrophyInfo { bit: 13, icon: "🎃", title: "Pumpkin Whisperer (100)", description: "Tickle the Corner Jack-o'-Lanterns 100 times.", reward: "Golden Pumpkin Bursts" },
    TrophyInfo { bit: 14, icon: "🪟", title: "Window Avalanche (1,500)", description: "Shake 1,500 settled leaves off your open windows.", reward: "Crisp Window drifts" },
    TrophyInfo { bit: 15, icon: "🕯️", title: "Eternal Watcher (180m)", description: "Enjoy Spookhush on your desktop for 180 active minutes.", reward: "Permanent 24k Cursor Trail" },
];

#[derive(Clone, Copy)]
pub struct Trophies {
    pub unlocked_mask: u32,
    pub golden_leaves: u32,
    pub best_combo: u32,
    pub vacuumed: u32,
    pub swept: u32,
    pub blown: u32,
    pub pumpkins: u32,
    pub window_shed: u32,
    pub active_minutes: u32,
    pub current_combo: u32,
}

impl Trophies {
    pub fn load() -> Trophies {
        Trophies {
            unlocked_mask: read(w!("trophyMask")).unwrap_or(0),
            golden_leaves: read(w!("goldenLeaves")).unwrap_or(0),
            best_combo: read(w!("bestCombo")).unwrap_or(0),
            vacuumed: read(w!("vacuumed")).unwrap_or(0),
            swept: read(w!("swept")).unwrap_or(0),
            blown: read(w!("blown")).unwrap_or(0),
            pumpkins: read(w!("pumpkins")).unwrap_or(0),
            window_shed: read(w!("windowShed")).unwrap_or(0),
            active_minutes: read(w!("activeMinutes")).unwrap_or(0),
            current_combo: 0,
        }
    }

    pub fn save(&self) {
        write(w!("trophyMask"), self.unlocked_mask);
        write(w!("goldenLeaves"), self.golden_leaves);
        write(w!("bestCombo"), self.best_combo);
        write(w!("vacuumed"), self.vacuumed);
        write(w!("swept"), self.swept);
        write(w!("blown"), self.blown);
        write(w!("pumpkins"), self.pumpkins);
        write(w!("windowShed"), self.window_shed);
        write(w!("activeMinutes"), self.active_minutes);
    }

    pub fn is_unlocked(&self, bit: u32) -> bool {
        (self.unlocked_mask & (1 << bit)) != 0
    }

    fn unlock(&mut self, bit: u32, unlocked: &mut Vec<&'static TrophyInfo>) {
        if !self.is_unlocked(bit) {
            self.unlocked_mask |= 1 << bit;
            if let Some(info) = TROPHIES.get(bit as usize) {
                unlocked.push(info);
            }
        }
    }

    pub fn golden_spawn_multiplier(&self, fever: bool) -> f32 {
        let mut mult = 1.0;
        if self.is_unlocked(0) { mult += 0.10; }
        if self.is_unlocked(2) { mult += 0.35; }
        if self.is_unlocked(3) { mult += 0.80; }
        if self.is_unlocked(4) { mult += 1.35; }
        if self.is_unlocked(5) { mult += 2.20; }
        if fever { mult *= 4.5; }
        mult
    }

    pub fn has_golden_cursor_trail(&self, fever: bool) -> bool {
        fever || self.is_unlocked(3) || self.is_unlocked(15)
    }

    pub fn apply_events(&mut self, events: SimulationEvents, add_minutes: u32) -> Vec<&'static TrophyInfo> {
        let mut newly_unlocked = Vec::new();
        let mut dirty = false;

        if events.first_rustle && !self.is_unlocked(0) {
            self.unlock(0, &mut newly_unlocked);
            dirty = true;
        }
        let caught_total = events.golden_caught + events.blood_moon_caught * 5;
        if caught_total > 0 {
            self.golden_leaves = self.golden_leaves.saturating_add(caught_total);
            self.current_combo = self.current_combo.saturating_add(events.golden_caught + events.blood_moon_caught);
            if self.current_combo > self.best_combo {
                self.best_combo = self.current_combo;
            }
            self.unlock(1, &mut newly_unlocked);
            if self.golden_leaves >= 15 { self.unlock(2, &mut newly_unlocked); }
            if self.golden_leaves >= 75 { self.unlock(3, &mut newly_unlocked); }
            if self.golden_leaves >= 250 { self.unlock(4, &mut newly_unlocked); }
            if self.golden_leaves >= 1_000 { self.unlock(5, &mut newly_unlocked); }
            if events.blood_moon_caught > 0 { self.unlock(6, &mut newly_unlocked); }
            if self.best_combo >= 5 { self.unlock(7, &mut newly_unlocked); }
            dirty = true;
        }
        if events.vacuumed > 0 {
            self.vacuumed = self.vacuumed.saturating_add(events.vacuumed);
            if self.vacuumed >= 500 { self.unlock(8, &mut newly_unlocked); }
            if self.vacuumed >= 5_000 { self.unlock(9, &mut newly_unlocked); }
            dirty = true;
        }
        if events.swept > 0 {
            self.swept = self.swept.saturating_add(events.swept);
            if self.swept >= 1_000 { self.unlock(10, &mut newly_unlocked); }
            if self.swept >= 10_000 { self.unlock(11, &mut newly_unlocked); }
            dirty = true;
        }
        if events.blown > 0 {
            self.blown = self.blown.saturating_add(events.blown);
            if self.blown >= 2_500 { self.unlock(12, &mut newly_unlocked); }
            dirty = true;
        }
        if events.pumpkins_touched > 0 {
            self.pumpkins = self.pumpkins.saturating_add(events.pumpkins_touched);
            if self.pumpkins >= 100 { self.unlock(13, &mut newly_unlocked); }
            dirty = true;
        }
        if events.window_shed > 0 {
            self.window_shed = self.window_shed.saturating_add(events.window_shed);
            if self.window_shed >= 1_500 { self.unlock(14, &mut newly_unlocked); }
            dirty = true;
        }
        if add_minutes > 0 {
            self.active_minutes = self.active_minutes.saturating_add(add_minutes);
            if self.active_minutes >= 180 { self.unlock(15, &mut newly_unlocked); }
            dirty = true;
        }
        if dirty {
            self.save();
        }
        newly_unlocked
    }

    pub fn summary_text(&self) -> String {
        let unlocked_count = (0..16).filter(|&b| self.is_unlocked(b)).count();
        let mut lines = Vec::new();
        lines.push(format!(
            "🎃 Spookhush Trophies: {}/16 Unlocked  |  🍂 Golden Leaves: {}  |  ⚡ Best Combo: {}x",
            unlocked_count, self.golden_leaves, self.best_combo
        ));
        lines.push(format!(
            "👻 Vacuumed: {}  |  🧹 Swept: {}  |  💨 Blown: {}  |  🎃 Pumpkins: {}  |  ⏱️ Active: {}m\n",
            self.vacuumed, self.swept, self.blown, self.pumpkins, self.active_minutes
        ));
        for t in &TROPHIES {
            let status = if self.is_unlocked(t.bit) { "✅ UNLOCKED" } else { "🔒 Locked" };
            lines.push(format!("{} {} — {} [{}]\n    {} ({})", t.icon, t.title, status, t.reward, t.description, self.progress_label(t.bit)));
        }
        lines.join("\n")
    }

    fn progress_label(&self, bit: u32) -> String {
        match bit {
            0 => format!("{}/1", self.is_unlocked(0) as u32),
            1 => format!("{}/1", self.golden_leaves.min(1)),
            2 => format!("{}/15", self.golden_leaves.min(15)),
            3 => format!("{}/75", self.golden_leaves.min(75)),
            4 => format!("{}/250", self.golden_leaves.min(250)),
            5 => format!("{}/1000", self.golden_leaves.min(1000)),
            6 => format!("{}/1", self.is_unlocked(6) as u32),
            7 => format!("{}/5x", self.best_combo.min(5)),
            8 => format!("{}/500", self.vacuumed.min(500)),
            9 => format!("{}/5000", self.vacuumed.min(5000)),
            10 => format!("{}/1000", self.swept.min(1000)),
            11 => format!("{}/10000", self.swept.min(10000)),
            12 => format!("{}/2500", self.blown.min(2500)),
            13 => format!("{}/100", self.pumpkins.min(100)),
            14 => format!("{}/1500", self.window_shed.min(1500)),
            15 => format!("{}m/180m", self.active_minutes.min(180)),
            _ => String::new(),
        }
    }
}

pub fn opens_at_login() -> bool {
    let mut buffer = [0u16; 1024];
    let mut size = (buffer.len() * 2) as u32;
    let status =
        unsafe { RegGetValueW(HKEY_CURRENT_USER, RUN, RUN_VALUE, RRF_RT_REG_SZ, None, Some(buffer.as_mut_ptr().cast::<c_void>()), Some(&mut size)) };
    if status != ERROR_SUCCESS {
        return false;
    }
    let length = buffer.iter().position(|&c| c == 0).unwrap_or(0);
    command().is_some_and(|command| command[..command.len() - 1] == buffer[..length])
}

pub fn set_opens_at_login(on: bool) -> WIN32_ERROR {
    unsafe {
        if !on {
            return RegDeleteKeyValueW(HKEY_CURRENT_USER, RUN, RUN_VALUE);
        }
        let Some(command) = command() else { return WIN32_ERROR(1) };
        RegSetKeyValueW(HKEY_CURRENT_USER, RUN, RUN_VALUE, REG_SZ.0, Some(command.as_ptr().cast()), (command.len() * 2) as u32)
    }
}

/// The quoted path of this executable, NUL-terminated.
fn command() -> Option<Vec<u16>> {
    let path = std::env::current_exe().ok()?;
    Some(format!("\"{}\"", path.display()).encode_utf16().chain([0]).collect())
}

fn read(name: PCWSTR) -> Option<u32> {
    let mut value = 0u32;
    let mut size = 4u32;
    let status =
        unsafe { RegGetValueW(HKEY_CURRENT_USER, KEY, name, RRF_RT_REG_DWORD, None, Some((&raw mut value).cast::<c_void>()), Some(&mut size)) };
    (status == ERROR_SUCCESS).then_some(value)
}

fn write(name: PCWSTR, value: u32) {
    unsafe {
        let _ = RegSetKeyValueW(HKEY_CURRENT_USER, KEY, name, REG_DWORD.0, Some((&raw const value).cast::<c_void>()), 4);
    }
}

/// The "Animation effects" setting: off means the person prefers less motion.
pub fn animations_enabled() -> bool {
    let mut enabled = BOOL(1);
    let result = unsafe {
        SystemParametersInfoW(SPI_GETCLIENTAREAANIMATION, 0, Some((&raw mut enabled).cast::<c_void>()), SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0))
    };
    result.is_err() || enabled.as_bool()
}
