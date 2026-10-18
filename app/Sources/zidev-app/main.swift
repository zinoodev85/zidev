// zidev.app: a window of its own for zidev (a terminal running `zidev`), with its own Dock icon.
// The cmd / alt keys zidev knows (`zidev keys`) go straight to it; the rest stay the app's (cmd-q, cmd-v).
// cmd-click on a `! command` Claude suggests runs it.
// A global hotkey (config "hotkey" in ~/.zidev/config.json, default cmd-cmd: cmd pressed twice) shows and
// hides the window;
// Window > Float on Top keeps it above other apps.
import AppKit
import Carbon.HIToolbox
import SwiftTerm

let shell = "/bin/zsh"
let defaultHotkey = "cmd-cmd"

/// key codes of the physical keys (US positions: on a German keyboard "z" is the key marked Y)
let keyCodes: [String: Int] = [
    "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E, "f": kVK_ANSI_F,
    "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
    "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R,
    "s": kVK_ANSI_S, "t": kVK_ANSI_T, "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
    "y": kVK_ANSI_Y, "z": kVK_ANSI_Z, "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
    "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
    "space": kVK_Space, "return": kVK_Return, "tab": kVK_Tab, "escape": kVK_Escape, "grave": kVK_ANSI_Grave,
    "f1": kVK_F1, "f2": kVK_F2, "f3": kVK_F3, "f4": kVK_F4, "f5": kVK_F5, "f6": kVK_F6, "f7": kVK_F7,
    "f8": kVK_F8, "f9": kVK_F9, "f10": kVK_F10, "f11": kVK_F11, "f12": kVK_F12]

/// "ctrl-alt-z" -> (key code, Carbon modifiers); nil when it names no key
func parseHotkey(_ s: String) -> (UInt32, UInt32)? {
    var parts = s.lowercased().split(separator: "-").map(String.init)
    guard let key = parts.popLast(), let code = keyCodes[key] else { return nil }
    var mods = 0
    for m in parts {
        switch m {
        case "cmd": mods |= cmdKey
        case "alt", "opt", "option": mods |= optionKey
        case "ctrl", "control": mods |= controlKey
        case "shift": mods |= shiftKey
        default: return nil
        }
    }
    return (UInt32(code), UInt32(mods))
}

/// ~/.zidev/config.json "hotkey"; "" or false: none
func configuredHotkey() -> String? {
    let path = NSHomeDirectory() + "/.zidev/config.json"
    guard let data = FileManager.default.contents(atPath: path),
          let conf = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return defaultHotkey }
    if let s = conf["hotkey"] as? String { return s.isEmpty ? nil : s }
    if conf["hotkey"] as? Bool == false { return nil }
    return defaultHotkey
}

var hotkeyAction: (() -> Void)?
var hotkeyRef: EventHotKeyRef?

/// a system-wide hotkey through Carbon (needs no accessibility permission)
func registerHotkey(_ s: String, _ action: @escaping () -> Void) {
    guard let (code, mods) = parseHotkey(s) else { return }
    hotkeyAction = action
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
        DispatchQueue.main.async { hotkeyAction?() }
        return noErr
    }, 1, &spec, nil, nil)
    RegisterEventHotKey(code, mods, EventHotKeyID(signature: OSType(0x7a696476), id: 1),  // 'zidv'
                        GetApplicationEventTarget(), 0, &hotkeyRef)
}

let tapMods: [String: CGEventFlags] = ["cmd": .maskCommand, "alt": .maskAlternate, "opt": .maskAlternate,
                                       "ctrl": .maskControl, "shift": .maskShift]
let anyMod: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]

/// a double tap of one modifier ("cmd-cmd"): pressed and let go alone, twice within tapGap
struct DoubleTap {
    static let tapGap = 0.4, holdMax = 0.3
    static var mod: CGEventFlags = []
    static var downAt = 0.0, lastTap = 0.0, clean = false, held = false
    static var tap: CFMachPort?

    static func flags(_ f: CGEventFlags) {
        let now = ProcessInfo.processInfo.systemUptime, m = f.intersection(anyMod)
        if m == mod {
            downAt = now; clean = true; held = true
        } else if m.isEmpty && held {
            held = false
            guard clean && now - downAt < holdMax else { lastTap = 0; return }
            if now - lastTap < tapGap {
                lastTap = 0
                DispatchQueue.main.async { hotkeyAction?() }
            } else {
                lastTap = now
            }
        } else {
            clean = false; held = false; lastTap = 0
        }
    }

    static func key() { clean = false; lastTap = 0 }  // cmd-c is no tap
}

/// "cmd-cmd" etc. through a listen-only event tap (asks once for Input Monitoring in System Settings)
func registerDoubleTap(_ mod: CGEventFlags, _ action: @escaping () -> Void) {
    hotkeyAction = action
    DoubleTap.mod = mod
    if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
    let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
    guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                                      eventsOfInterest: CGEventMask(mask), callback: { _, type, e, _ in
        switch type {
        case .flagsChanged: DoubleTap.flags(e.flags)
        case .keyDown: DoubleTap.key()
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let t = DoubleTap.tap { CGEvent.tapEnable(tap: t, enable: true) }
        default: break
        }
        return Unmanaged.passUnretained(e)
    }, userInfo: nil) else { return }
    DoubleTap.tap = tap
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
}

/// a hotkey from the config: "cmd-cmd" (a double tap) or a combo like "ctrl-alt-z"
func registerAnyHotkey(_ s: String, _ action: @escaping () -> Void) {
    let parts = s.lowercased().split(separator: "-").map(String.init)
    if parts.count == 2, parts[0] == parts[1], let mod = tapMods[parts[0]] {
        registerDoubleTap(mod, action)
    } else {
        registerHotkey(s, action)
    }
}

/// `zidev keys`: key name (cmd-w, alt-left, cmd-shift-z) -> what to send. Asked through a login shell,
/// so the zidev on your PATH answers (the app starts from Finder without your PATH).
func loadKeys() -> [String: String] {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: shell)
    p.arguments = ["-lc", "zidev keys"]
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return [:] }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: String] ?? [:]
}

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}

func termColor(_ hex: UInt32) -> SwiftTerm.Color {
    SwiftTerm.Color(red: UInt16(hex >> 16 & 0xff) * 257, green: UInt16(hex >> 8 & 0xff) * 257,
                    blue: UInt16(hex & 0xff) * 257)
}

/// the colors of zidev's iTerm profile, so zidev looks the same in its app
struct Theme {
    let bg: UInt32, fg: UInt32, cursor: UInt32, selection: UInt32, ansi: [UInt32]
    static let dark = Theme(bg: 0x010c18, fg: 0xecdef4, cursor: 0x38ff9d, selection: 0x1d3a4f, ansi: [
        0x0b3b61, 0xff3a3a, 0x52ffd0, 0xfff383, 0x1376f9, 0xc792ea, 0xff5ed4, 0x16fda2,
        0x63686d, 0xff54b0, 0x74ffd8, 0xfcf5ae, 0x388eff, 0xae81ff, 0xff6ad7, 0x60fbbf])
    static let light = Theme(bg: 0xfafafa, fg: 0x101010, cursor: 0x000000, selection: 0xb3d7ff, ansi: [
        0x14191e, 0xb43c2a, 0x00c200, 0xc7c400, 0x2744c7, 0xc040be, 0x00c5c7, 0xc7c7c7,
        0x686868, 0xdd7975, 0x58e790, 0xece100, 0xa7abf2, 0xe17ee1, 0x60fdff, 0xffffff])
}

final class ZidevView: LocalProcessTerminalView {
    var keys: [String: String] = [:]

    /// cmd-shift-z, alt-left, cmd-/ : the name `zidev keys` uses for this key press
    func name(_ e: NSEvent) -> String? {
        let f = e.modifierFlags
        guard f.contains(.command) || f.contains(.option), !f.contains(.control) else { return nil }
        var key: String
        switch e.specialKey {
        case .leftArrow?: key = "left"
        case .rightArrow?: key = "right"
        case .upArrow?: key = "up"
        case .downArrow?: key = "down"
        case .backspace?, .delete?: key = "backspace"
        default:
            guard let c = e.charactersIgnoringModifiers?.lowercased(), c.count == 1 else { return nil }
            key = c
        }
        // shift that only makes the character (/ is shift-7 on a German keyboard) is not part of the name
        let shift = f.contains(.shift) && (key.count > 1 || key.first!.isLetter)
        return (f.contains(.command) ? "cmd-" : "") + (f.contains(.option) ? "alt-" : "") +
            (shift ? "shift-" : "") + key
    }

    /// cmd-click: sent to tmux as a ctrl-alt-click (a terminal can't report cmd), zidev's binding
    /// runs a `! command` there; SwiftTerm would open a link itself
    func cmdClick(_ e: NSEvent) -> Bool {
        guard e.modifierFlags.contains(.command), e.window === window else { return false }
        let p = convert(e.locationInWindow, from: nil)
        guard bounds.contains(p) else { return false }
        // the cell size as SwiftTerm measures it (computeFontDimensions), snapped to the pixel grid
        let scale = window?.backingScaleFactor ?? 2
        let w = (font.advancement(forGlyph: font.glyph(withName: "W")).width * scale).rounded() / scale
        let h = ceil(ceil((font.ascender - font.descender + font.leading) * lineSpacing) * scale) / scale
        // the view is flipped: y grows downward from the first row
        let y = isFlipped ? p.y : bounds.height - p.y
        let col = Int(p.x / w) + 1, row = Int(y / h) + 1
        send(txt: "\u{1b}[<24;\(col);\(row)" + (e.type == .leftMouseDown ? "M" : "m"))
        return true
    }

    /// a key zidev knows: sent to it, not handled by the terminal or the menu
    func zidevKey(_ e: NSEvent) -> Bool {
        guard window?.isKeyWindow == true, window?.firstResponder === self,
              let n = name(e), let seq = keys[n] else { return false }
        send(txt: seq)
        return true
    }
}

final class App: NSObject, NSApplicationDelegate, LocalProcessTerminalViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    var term: ZidevView!
    var look: NSKeyValueObservation?
    var keyWatch: Any?
    var clickWatch: Any?

    func applicationDidFinishLaunching(_ n: Notification) {
        menu()
        // colors 16-255 as xterm (and iTerm) has them, not mixed from the 16: Claude's bars inside tmux are those
        var options = TerminalOptions.default
        options.ansi256PaletteStrategy = .xterm
        term = ZidevView(frame: NSRect(x: 0, y: 0, width: 1200, height: 760), options: options)
        term.processDelegate = self
        term.optionAsMetaKey = true
        term.font = NSFont(name: "MesloLGS-NF-Regular", size: 16) ?? NSFont(name: "SF Mono", size: 13)
            ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        term.fontSmoothing = false  // thin strokes, as iTerm draws text on a Retina screen
        // a margin around the text, as iTerm has
        let frame = NSView(frame: term.frame.insetBy(dx: -8, dy: -4))
        term.frame.origin = CGPoint(x: 8, y: 4)
        term.autoresizingMask = [.width, .height]
        frame.addSubview(term)
        window = NSWindow(contentRect: frame.frame, styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "zidev"
        window.titlebarAppearsTransparent = true
        window.contentView = frame
        window.delegate = self
        window.setFrameAutosaveName("zidev")
        if !window.setFrameUsingName("zidev") { window.center() }
        paint()
        look = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in self?.paint() }
        window.makeKeyAndOrderFront(nil)
        // the GPU draws the text: CoreGraphics lays out every changed row on the CPU, ~8% of a core for a
        // Claude spinner alone; without Metal it stays on CoreGraphics
        try? term.setUseMetal(true)
        window.makeFirstResponder(term)
        keyWatch = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            self?.term.zidevKey(e) == true ? nil : e  // before the menu and the terminal see it
        }
        clickWatch = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] e in
            guard let self else { return e }
            if self.titleDoubleClick(e) { return nil }
            return self.term.cmdClick(e) ? nil : e
        }
        if let key = configuredHotkey() {
            registerAnyHotkey(key) { [weak self] in self?.toggleShown() }
        }
        setFloating(UserDefaults.standard.bool(forKey: "floatOnTop"))
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.global().async {
            let keys = loadKeys()
            DispatchQueue.main.async { self.term.keys = keys }
        }
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["TERM_PROGRAM"] = "zidev-app"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        env.removeValue(forKey: "TMUX")
        let run = "command -v zidev >/dev/null && exec zidev || " +
            "{ echo 'zidev is not on your PATH: brew install zinoodev85/zidev/zidev'; read -k1; }"
        term.startProcess(executable: shell, args: ["-lic", run], environment: env.map { "\($0)=\($1)" },
                          execName: "-zsh", currentDirectory: NSHomeDirectory())
    }

    /// the hotkey: zidev in front hides it, else it comes to the front (unminimized)
    func toggleShown() {
        if NSApp.isActive && window.isVisible && !window.isMiniaturized {
            NSApp.hide(nil)
        } else {
            NSApp.unhide(nil)
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    var floatItem: NSMenuItem?

    /// Window > Float on Top: above every other app's windows; remembered
    func setFloating(_ on: Bool) {
        window.level = on ? .floating : .normal
        window.collectionBehavior = on ? [.fullScreenAuxiliary, .moveToActiveSpace] : []
        floatItem?.state = on ? .on : .off
        UserDefaults.standard.set(on, forKey: "floatOnTop")
    }

    @objc func toggleFloating(_ sender: Any?) { setFloating(window.level != .floating) }

    /// a double click on the title bar fills the screen (and back), whatever System Settings say
    func titleDoubleClick(_ e: NSEvent) -> Bool {
        guard e.type == .leftMouseDown, e.clickCount == 2, e.window === window,
              e.locationInWindow.y > window.contentLayoutRect.maxY else { return false }
        window.zoom(nil)
        return true
    }

    /// light or dark, as macOS is: background, text and the 16 colors
    func paint() {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let t = dark ? Theme.dark : Theme.light
        term.installColors(t.ansi.map(termColor))
        term.nativeBackgroundColor = color(t.bg)
        term.nativeForegroundColor = color(t.fg)
        term.caretColor = color(t.cursor)
        term.selectedTextBackgroundColor = color(t.selection)
        window.backgroundColor = color(t.bg)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }

    func menu() {
        let main = NSMenu()
        let app = NSMenu()
        app.addItem(withTitle: "About zidev", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "Hide zidev", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Quit zidev", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Paste", action: #selector(TerminalView.paste(_:)), keyEquivalent: "v")
        let win = NSMenu(title: "Window")
        win.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        let full = win.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        full.keyEquivalentModifierMask = [.command, .control]
        win.addItem(.separator())
        floatItem = win.addItem(withTitle: "Float on Top", action: #selector(toggleFloating(_:)), keyEquivalent: "")
        floatItem?.target = self
        for (title, sub) in [("zidev", app), ("Edit", edit), ("Window", win)] {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.submenu = sub
            main.addItem(item)
        }
        NSApp.mainMenu = main
        NSApp.windowsMenu = win
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { true }

    // zidev ended (detached, or its server stopped): the sessions keep running; the app goes
    func processTerminated(source: TerminalView, exitCode: Int32?) { NSApp.terminate(nil) }
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = App()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
