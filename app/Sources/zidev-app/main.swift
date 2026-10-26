// zidev.app: a window of its own for zidev (a terminal running `zidev`), with its own Dock icon.
// The cmd / alt keys zidev knows (`zidev keys`) go straight to it; the rest stay the app's (cmd-q, cmd-v).
// cmd-click on a `! command` Claude suggests runs it.
// A global hotkey (config "hotkey" in ~/.zidev/config.json, default cmd-cmd: cmd pressed twice) shows and
// hides the window;
// Window > Float on Top keeps it above other apps.
// shift-shift opens zidev's palette over any app. The app keeps the last copies (~/.zidev/clips):
// ctrl-cmd-1 … 5 paste them, ctrl-cmd-0 pastes the clipboard as plain text.
import AppKit
import Carbon.HIToolbox
import CryptoKit
import ServiceManagement
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

/// what each hotkey does, by its id
var hotkeyActions: [UInt32: () -> Void] = [:]

/// a system-wide hotkey through Carbon (needs no accessibility permission)
func registerHotkey(_ s: String, _ action: @escaping () -> Void) {
    guard let (code, mods) = parseHotkey(s) else { return }
    if hotkeyActions.isEmpty {  // one handler for all of them: it finds the action by the hotkey's id
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            DispatchQueue.main.async { hotkeyActions[id.id]?() }
            return noErr
        }, 1, &spec, nil, nil)
    }
    let id = UInt32(hotkeyActions.count + 1)
    hotkeyActions[id] = action
    var ref: EventHotKeyRef?
    RegisterEventHotKey(code, mods, EventHotKeyID(signature: OSType(0x7a696476), id: id),  // 'zidv'
                        GetApplicationEventTarget(), 0, &ref)
}

let tapMods: [String: CGEventFlags] = ["cmd": .maskCommand, "alt": .maskAlternate, "opt": .maskAlternate,
                                       "ctrl": .maskControl, "shift": .maskShift]
let anyMod: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]

/// a double tap of one modifier ("cmd-cmd", "shift-shift"): pressed and let go alone, twice within tapGap
struct DoubleTap {
    static let tapGap = 0.4, holdMax = 0.3
    static var actions: [UInt64: () -> Void] = [:]  // what a double tap does, by its modifier
    static var mod: CGEventFlags = []  // the modifier pressed last
    static var downAt = 0.0, lastTap = 0.0, clean = false, held = false
    static var tap: CFMachPort?

    static func flags(_ f: CGEventFlags) {
        let now = ProcessInfo.processInfo.systemUptime, m = f.intersection(anyMod)
        if actions[m.rawValue] != nil {
            if m != mod { lastTap = 0 }  // shift then cmd is no double tap
            mod = m; downAt = now; clean = true; held = true
        } else if m.isEmpty && held {
            held = false
            guard clean && now - downAt < holdMax else { lastTap = 0; return }
            if now - lastTap < tapGap {
                lastTap = 0
                if let action = actions[mod.rawValue] { DispatchQueue.main.async { action() } }
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
    let first = DoubleTap.actions.isEmpty
    DoubleTap.actions[mod.rawValue] = action
    guard first else { return }  // one tap sees them all
    // without Input Monitoring a tap sees only this app's keys: cmd-cmd hides zidev but never shows it again.
    // Asked once; the tap comes as soon as it is allowed, no restart
    if !CGPreflightListenEventAccess() {
        CGRequestListenEventAccess()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            guard CGPreflightListenEventAccess() else { return }
            timer.invalidate()
            createTap()
        }
        return
    }
    createTap()
}

func createTap() {
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

/// what each `notifyutil -p zidev.<name>` does, by its name (zidev sends them, and the tests)
var listeners: [String: () -> Void] = [:]

func listen(_ name: String, _ action: @escaping () -> Void) {
    listeners[name] = action
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, name, _, _ in
        guard let name = name?.rawValue as String? else { return }
        DispatchQueue.main.async { listeners[name]?() }
    }, name as CFString, nil, .deliverImmediately)
}

/// one type of a copy, with its data ("public.utf8-plain-text", "public.png", …)
struct Kept: Codable {
    let type: String
    let data: Data
}

/// a copy in the clipboard history (index.json, which zidev's palette lists)
struct Clip: Codable {
    enum Kind: String, Codable { case text, files, image }
    let id: String
    let t: Double
    let kind: Kind
    let text: String  // its text, the files' paths, or "Image 800 × 600"
    let app: String  // the app it was copied in
    let hash: String  // the same copy again replaces it
}

/// the clipboard history in ~/.zidev/clips, only for me (0700 / 0600): index.json, newest first, and
/// <id>.plist with all its types for each copy. What a password manager marks secret is never kept
final class Clips {
    static let most = 50, bigType = 20 << 20
    static let secret: Set<String> = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType",
                                      "org.nspasteboard.AutoGeneratedType", "com.agilebits.onepassword"]
    let dir = NSHomeDirectory() + "/.zidev/clips/"
    let board = NSPasteboard.general
    var index: [Clip] = []
    var seen = -1  // the clipboard's changeCount looked at last; -1: what is on it at start is kept too
    var timer: Timer?

    /// ZI77: the clipboard is the one thing looked at on a timer
    func start() {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir)
        if let data = FileManager.default.contents(atPath: dir + "index.json"),
           let list = try? JSONDecoder().decode([Clip].self, from: data) {
            index = list
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.look() }
    }

    /// a new copy on the clipboard: kept on top
    func look() {
        guard board.changeCount != seen else { return }
        seen = board.changeCount
        let types = Set((board.types ?? []).map(\.rawValue))
        guard types.isDisjoint(with: Clips.secret), let items = board.pasteboardItems, !items.isEmpty else { return }
        let kept = items.map { item in
            item.types.compactMap { type -> Kept? in
                guard let data = item.data(forType: type), data.count <= Clips.bigType else { return nil }
                return Kept(type: type.rawValue, data: data)
            }
        }
        guard let (kind, text) = describe() else { return }
        var digest = SHA256()
        if kind == .image {  // an image by its data, text and files by what they say
            for k in kept.joined() { digest.update(data: k.data) }
        } else {
            digest.update(data: Data(text.utf8))
        }
        let hash = digest.finalize().map { String(format: "%02x", $0) }.joined()
        let id = String(Int(Date().timeIntervalSince1970 * 1000))
        guard let plist = try? PropertyListEncoder.binary.encode(kept), write(plist, dir + id + ".plist") else { return }
        for old in index where old.hash == hash { drop(old) }
        let app = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
        index.insert(Clip(id: id, t: Date().timeIntervalSince1970, kind: kind, text: String(text.prefix(2000)),
                          app: app, hash: hash), at: 0)
        while index.count > Clips.most { drop(index[index.count - 1]) }
        if let json = try? JSONEncoder().encode(index) { _ = write(json, dir + "index.json") }
    }

    /// what the copy on the clipboard is: files (their paths), text, or an image (its size); nil: none of them
    func describe() -> (Clip.Kind, String)? {
        let files = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        if !files.isEmpty { return (.files, files.map(\.path).joined(separator: "\n")) }
        if let text = board.string(forType: .string), !text.isEmpty { return (.text, text) }
        if let image = NSImage(pasteboard: board), let rep = image.representations.first {
            return (.image, "Image \(rep.pixelsWide) × \(rep.pixelsHigh)")
        }
        return nil
    }

    func drop(_ clip: Clip) {
        index.removeAll { $0.id == clip.id }
        try? FileManager.default.removeItem(atPath: dir + clip.id + ".plist")
    }

    /// a file only I can read, written whole (a reader never sees half of it)
    func write(_ data: Data, _ path: String) -> Bool {
        let part = path + ".part"
        guard FileManager.default.createFile(atPath: part, contents: data, attributes: [.posixPermissions: 0o600])
        else { return false }
        return rename(part, path) == 0
    }

    /// ctrl-cmd-1 … 5: the nth copy (1 = newest)
    func paste(nth: Int) {
        guard nth <= index.count else { return }
        paste(id: index[nth - 1].id)
    }

    func paste(id: String) {
        guard let data = FileManager.default.contents(atPath: dir + id + ".plist"),
              let kept = try? PropertyListDecoder().decode([[Kept]].self, from: data) else { return }
        paste(kept)
    }

    /// ctrl-cmd-0: the clipboard as plain text
    func pastePlain() {
        guard let text = board.string(forType: .string) else { return }
        paste([[Kept(type: NSPasteboard.PasteboardType.string.rawValue, data: Data(text.utf8))]])
    }

    /// ZI76: pasted into the app in front (cmd-v), then the clipboard is as it was; the history stays as it is
    func paste(_ items: [[Kept]]) {
        let before = (board.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { Kept(type: type.rawValue, data: $0) } }
        }
        put(items)
        // without Accessibility no key can be sent (macOS asks for it): the copy stays on the clipboard for cmd-v
        let ask = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(ask) else { return }
        whenKeysUp(tries: 50) {
            pressCmdV()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.put(before) }
        }
    }

    /// these items on the clipboard; not a new copy
    func put(_ items: [[Kept]]) {
        board.clearContents()
        board.writeObjects(items.map { kept in
            let item = NSPasteboardItem()
            for k in kept { item.setData(k.data, forType: NSPasteboard.PasteboardType(k.type)) }
            return item
        })
        seen = board.changeCount
    }
}

extension PropertyListEncoder {
    static var binary: PropertyListEncoder {
        let e = PropertyListEncoder()
        e.outputFormat = .binary
        return e
    }
}

/// runs once no modifier key is held (at most ~1 s later): cmd-v sent while ctrl is still down is ctrl-cmd-v
func whenKeysUp(tries: Int, _ then: @escaping () -> Void) {
    if tries == 0 || CGEventSource.flagsState(.combinedSessionState).intersection(anyMod).isEmpty {
        then()
        return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { whenKeysUp(tries: tries - 1, then) }
}

/// cmd-v, as if pressed: the app in front pastes
func pressCmdV() {
    let source = CGEventSource(stateID: .combinedSessionState)
    for down in [true, false] {
        let e = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: down)
        e?.flags = .maskCommand
        e?.post(tap: .cgSessionEventTap)
    }
}

/// what `zsh <args>` prints
func shellOutput(_ args: [String]) -> Data {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: shell)
    p.arguments = args
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return Data() }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return data
}

/// The app starts from Finder, the Dock or at login without your PATH: take the one your shell sets (also in
/// ~/.zshrc), so the zidev on your PATH answers, as in a terminal
func takeShellPath() {
    let printed = String(decoding: shellOutput(["-lic", "print -r -- \"zidev-path=$PATH\""]), as: UTF8.self)
    if let line = printed.split(separator: "\n").last(where: { $0.hasPrefix("zidev-path=") }) {
        setenv("PATH", String(line.dropFirst("zidev-path=".count)), 1)
    }
}

/// `zidev keys`: key name (cmd-w, alt-left, cmd-shift-z) -> what to send
func loadKeys() -> [String: String] {
    (try? JSONSerialization.jsonObject(with: shellOutput(["-lc", "zidev keys"]))) as? [String: String] ?? [:]
}

/// `zidev palette-argv`: the command that starts the palette panel at once (no login shell first)
func loadPaletteArgv() -> [String] {
    (try? JSONSerialization.jsonObject(with: shellOutput(["-lc", "zidev palette-argv"]))) as? [String] ?? []
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
    /// the emulator, kept from the first reply it sends (SwiftTerm hands it out nowhere else)
    nonisolated(unsafe) var emulator: Terminal?

    nonisolated override func send(source: Terminal, data: ArraySlice<UInt8>) {
        emulator = source
        super.send(source: source, data: data)
    }

    /// `notifyutil -p zidev.probe`: the rows as this view has them -> ~/.zidev/probe-screen.txt; with
    /// ~/.zidev/probe-click ("col row", 0-based) a cmd-click on that cell first, as a hand would make it;
    /// with ~/.zidev/probe-paste a cmd-v of its text.
    /// more: the app's own line to add on top; below: what to add under the rows
    func probe(more: String, below: String) {
        let dir = NSHomeDirectory() + "/.zidev/"
        if let spec = try? String(contentsOfFile: dir + "probe-click", encoding: .utf8) {
            try? FileManager.default.removeItem(atPath: dir + "probe-click")
            let n = spec.split(separator: " ").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            let plain = spec.contains("plain")  // "col row plain": a plain click, no cmd
            if n.count == 2, let win = window {
                let scale = win.backingScaleFactor
                let w = (font.advancement(forGlyph: font.glyph(withName: "W")).width * scale).rounded() / scale
                let h = ceil(ceil((font.ascender - font.descender + font.leading) * lineSpacing) * scale) / scale
                let p = convert(NSPoint(x: (CGFloat(n[0]) + 0.5) * w, y: bounds.height - (CGFloat(n[1]) + 0.5) * h), to: nil)
                for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                    if let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: plain ? [] : .command,
                                                  timestamp: 0, windowNumber: win.windowNumber, context: nil,
                                                  eventNumber: 0, clickCount: 1, pressure: 1) {
                        if plain { type == .leftMouseDown ? mouseDown(with: e) : mouseUp(with: e) } else { _ = cmdClick(e) }
                    }
                }
            }
        }
        if let press = try? String(contentsOfFile: dir + "probe-press", encoding: .utf8) {  // "cmd-k": that key pressed
            try? FileManager.default.removeItem(atPath: dir + "probe-press")
            let parts = press.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-").map(String.init)
            var flags: NSEvent.ModifierFlags = []
            for m in parts.dropLast() { flags.insert(["cmd": .command, "alt": .option, "shift": .shift][m] ?? []) }
            if let c = parts.last, let win = window,
               let e = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                                        windowNumber: win.windowNumber, context: nil, characters: c,
                                        charactersIgnoringModifiers: c, isARepeat: false, keyCode: 0) {
                _ = zidevKey(e, focused: true)  // as the key monitor sees it, in front or not
            }
        }
        if let keys = try? String(contentsOfFile: dir + "probe-keys", encoding: .utf8) {  // "cmd none cmd key none"
            try? FileManager.default.removeItem(atPath: dir + "probe-keys")
            for k in keys.split(whereSeparator: \.isWhitespace) {  // as the event tap sees them; key: a key press
                if k == "key" { DoubleTap.key() } else { DoubleTap.flags(k == "none" ? [] : tapMods[String(k)] ?? []) }
            }
        }
        if let text = try? String(contentsOfFile: dir + "probe-paste", encoding: .utf8) {  // cmd-v of this text
            try? FileManager.default.removeItem(atPath: dir + "probe-paste")
            let board = NSPasteboard.general  // the clipboard as it was, all its types, comes back after
            let kept = (board.pasteboardItems ?? []).map { item in
                item.types.reduce(into: NSPasteboardItem()) { copy, type in
                    if let data = item.data(forType: type) { copy.setData(data, forType: type) }
                }
            }
            board.clearContents()
            board.setString(text, forType: .string)
            paste(self)
            board.clearContents()
            board.writeObjects(kept)
        }
        let shown = NSApp.isActive && !NSApp.isHidden && window?.isVisible == true
        guard let t = emulator else { return }
        var out = "shown \(shown) floating \(window?.level == .floating) rows \(t.rows) yDisp \(t.buffer.yDisp) inputMonitoring \(CGPreflightListenEventAccess()) " +
            "tap \(DoubleTap.tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false) keys \(keys.count) \(more)\n"
        for r in 0..<t.rows {
            out += String(format: "%2d ", r) + (t.getLine(row: r)?.translateToString(trimRight: true) ?? "-") + "\n"
        }
        try? (out + below).write(toFile: dir + "probe-screen.txt", atomically: true, encoding: .utf8)
    }

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
        guard bounds.contains(convert(e.locationInWindow, from: nil)) else { return false }
        // SwiftTerm reports it at the cell it hits, as any click (cells counted here hit a row off)
        guard let ctrlAlt = NSEvent.mouseEvent(with: e.type, location: e.locationInWindow,
                                               modifierFlags: [.control, .option], timestamp: e.timestamp,
                                               windowNumber: e.windowNumber, context: nil, eventNumber: e.eventNumber,
                                               clickCount: e.clickCount, pressure: e.pressure) else { return false }
        if e.type == .leftMouseDown { mouseDown(with: ctrlAlt) } else { mouseUp(with: ctrlAlt) }
        return true
    }

    /// a key zidev knows: sent to it, not handled by the terminal or the menu
    func zidevKey(_ e: NSEvent, focused: Bool = false) -> Bool {
        guard focused || (window?.isKeyWindow == true && window?.firstResponder === self),
              let n = name(e), let seq = keys[n] else { return false }
        send(txt: seq)
        return true
    }
}

/// the palette over another app (shift-shift): it takes the keys, that app stays in front
final class PalettePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class App: NSObject, NSApplicationDelegate, LocalProcessTerminalViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    var term: ZidevView!
    var panel: PalettePanel?
    var paletteTerm: ZidevView?
    let clips = Clips()
    var look: NSKeyValueObservation?
    var keyWatch: Any?
    var clickWatch: Any?
    var paletteArgv: [String] = []
    var zidevEnded = false  // ZI79: zidev ended in the window; it starts again when the window shows

    func applicationDidFinishLaunching(_ n: Notification) {
        menu()
        term = makeTerm(NSRect(x: 0, y: 0, width: 1200, height: 760))
        let frame = framed(term)
        window = NSWindow(contentRect: frame.frame, styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "zidev"
        window.titlebarAppearsTransparent = true
        window.contentView = frame
        window.delegate = self
        window.setFrameAutosaveName("zidev")
        if !window.setFrameUsingName("zidev") { window.center() }
        paint()
        // paint() belongs to the main thread
        look = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in DispatchQueue.main.async { self?.paint() } }
        window.makeKeyAndOrderFront(nil)
        // the GPU draws the text: CoreGraphics lays out every changed row on the CPU, ~8% of a core for a
        // Claude spinner alone; without Metal it stays on CoreGraphics
        try? term.setUseMetal(true)
        window.makeFirstResponder(term)
        keyWatch = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self else { return e }
            // in the palette over another app cmd-q, cmd-h, … would act on zidev: only cmd-v (paste) works there
            if e.window === self.panel && e.modifierFlags.contains(.command) && e.charactersIgnoringModifiers != "v" {
                return nil
            }
            return self.term.zidevKey(e) ? nil : e  // before the menu and the terminal see it
        }
        clickWatch = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] e in
            guard let self else { return e }
            if self.titleDoubleClick(e) { return nil }
            return self.term.cmdClick(e) ? nil : e
        }
        if let key = configuredHotkey() {
            registerAnyHotkey(key) { [weak self] in self?.toggleShown() }
        }
        registerDoubleTap(.maskShift) { [weak self] in self?.togglePalette() }
        clips.start()
        for nth in 1...5 {
            registerHotkey("ctrl-cmd-\(nth)") { [weak self] in self?.clips.paste(nth: nth) }
        }
        registerHotkey("ctrl-cmd-0") { [weak self] in self?.clips.pastePlain() }
        setFloating(UserDefaults.standard.bool(forKey: "floatOnTop"))
        listen("zidev.probe") { [weak self] in self?.probe() }
        listen("zidev.paste") { [weak self] in self?.pastePicked() }
        listen("zidev.show") { [weak self] in self?.show() }
        NSApp.activate(ignoringOtherApps: true)
        takeShellPath()  // before the keys and the palette: both ask zidev
        reloadKeys(tries: 30)
        startLoginItem()
        startZidev()
    }

    /// zidev in the window's terminal
    func startZidev() {
        let run = "command -v zidev >/dev/null && exec zidev || " +
            "{ echo 'zidev is not on your PATH: brew install zinoodev85/zidev/zidev'; read -k1; }"
        term.startProcess(executable: shell, args: ["-lic", run], environment: termEnv(),
                          execName: "-zsh", currentDirectory: NSHomeDirectory())
    }

    /// a terminal view as zidev has it: its font, xterm's 256 colors
    func makeTerm(_ rect: NSRect) -> ZidevView {
        // colors 16-255 as xterm (and iTerm) has them, not mixed from the 16: Claude's bars inside tmux are those
        var options = TerminalOptions.default
        options.ansi256PaletteStrategy = .xterm
        let t = ZidevView(frame: rect, options: options)
        t.processDelegate = self
        t.optionAsMetaKey = true
        t.font = NSFont(name: "MesloLGS-NF-Regular", size: 16) ?? NSFont(name: "SF Mono", size: 13)
            ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        t.fontSmoothing = false  // thin strokes, as iTerm draws text on a Retina screen
        return t
    }

    /// the terminal view in a margin, as iTerm has it
    func framed(_ t: ZidevView) -> NSView {
        let frame = NSView(frame: t.frame.insetBy(dx: -8, dy: -4))
        t.frame.origin = CGPoint(x: 8, y: 4)
        t.autoresizingMask = [.width, .height]
        frame.addSubview(t)
        return frame
    }

    /// what zidev runs in: a 256-color terminal, outside tmux
    func termEnv() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["TERM_PROGRAM"] = "zidev-app"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        env.removeValue(forKey: "TMUX")
        return env.map { "\($0)=\($1)" }
    }

    /// the hotkey: zidev in front hides it, else it comes to the front
    func toggleShown() {
        if NSApp.isActive && window.isVisible && !window.isMiniaturized {
            NSApp.hide(nil)
        } else {
            show()
        }
    }

    /// zidev's window in front (unminimized); also `zidev.show`, after something picked in the palette panel
    func show() {
        if zidevEnded {
            zidevEnded = false
            startZidev()
        }
        NSApp.unhide(nil)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// ZI73, shift-shift: zidev in front opens its cmd-k palette; over another app the palette panel;
    /// in WebStorm (and the other JetBrains IDEs) shift-shift stays theirs. Again: the panel closes
    func togglePalette() {
        if panel != nil {
            closePalette()
            return
        }
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        if front.hasPrefix("com.jetbrains.") { return }
        if NSApp.isActive {
            if let seq = term.keys["cmd-k"] { term.send(txt: seq) }
            return
        }
        openPalette()
    }

    /// only the palette (`zidev palette float`) in a small panel at the top of the screen with the mouse, like
    /// Spotlight; the app in front stays in front
    func openPalette() {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
                ?? NSScreen.main else { return }
        let area = screen.visibleFrame
        let size = NSSize(width: min(1100, area.width * 0.7), height: min(560, area.height * 0.6))
        let rect = NSRect(x: area.midX - size.width / 2, y: area.maxY - size.height - area.height * 0.12,
                          width: size.width, height: size.height)
        let p = PalettePanel(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
                             defer: false)
        p.level = .modalPanel
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.hidesOnDeactivate = false
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.delegate = self
        let t = makeTerm(NSRect(x: 0, y: 0, width: size.width - 16, height: size.height - 8))
        let frame = framed(t)
        frame.wantsLayer = true
        frame.layer?.cornerRadius = 10
        frame.layer?.masksToBounds = true
        p.contentView = frame
        panel = p
        paletteTerm = t
        paint()
        p.makeKeyAndOrderFront(nil)
        p.makeFirstResponder(t)
        // the command zidev gave (python on its compiled code), while its files are there (a brew upgrade moves
        // them); else through the login shell, which takes longer
        if !paletteArgv.isEmpty && paletteArgv.filter({ $0.hasPrefix("/") }).allSatisfy(FileManager.default.fileExists) {
            t.startProcess(executable: paletteArgv[0], args: Array(paletteArgv.dropFirst()), environment: termEnv(),
                           currentDirectory: NSHomeDirectory())
        } else {
            t.startProcess(executable: shell, args: ["-lc", "exec zidev palette float"], environment: termEnv(),
                           execName: "-zsh", currentDirectory: NSHomeDirectory())
        }
    }

    func closePalette() {
        guard let p = panel else { return }
        panel = nil
        p.orderOut(nil)
        paletteTerm?.terminate()
        paletteTerm = nil
    }

    /// a click into another app closes the palette panel
    func windowDidResignKey(_ n: Notification) {
        if let p = panel, n.object as AnyObject === p { closePalette() }
    }

    /// `zidev.paste`: the copy picked in the palette's Clipboard tab (its id in clips/paste) goes into the app
    /// in front, once the panel is away
    func pastePicked() {
        let path = clips.dir + "paste"
        guard let id = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(atPath: path)
        closePalette()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.clips.paste(id: id.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /// `notifyutil -p zidev.probe` (see ZidevView.probe), also the panel, the app in front and the copies kept;
    /// ~/.zidev/probe-type: that text typed into the palette panel first
    func probe() {
        let typed = NSHomeDirectory() + "/.zidev/probe-type"
        if let text = try? String(contentsOfFile: typed, encoding: .utf8) {
            try? FileManager.default.removeItem(atPath: typed)
            paletteTerm?.send(txt: text)
        }
        let close = NSHomeDirectory() + "/.zidev/probe-close"
        if FileManager.default.fileExists(atPath: close) {  // a click on the window's close button
            try? FileManager.default.removeItem(atPath: close)
            window.performClose(nil)
        }
        var below = ""
        if let p = paletteTerm {  // what the panel shows
            p.selectAll()
            below = "panel:\n" + (p.getSelection() ?? "") + "\n"
            p.selectNone()
        }
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "-"
        term.probe(more: "panel \(panel != nil) front \(front) clips \(clips.index.count)", below: below)
    }

    /// ZI78: zidev.app starts at login, once it is the one in Applications (`zidev app`); asked once, so
    /// switching it off in System Settings stays off
    func startLoginItem() {
        let defaults = UserDefaults.standard
        guard Bundle.main.bundlePath.hasSuffix("Applications/zidev.app"), !defaults.bool(forKey: "loginItem") else { return }
        if (try? SMAppService.mainApp.register()) != nil { defaults.set(true, forKey: "loginItem") }
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

    /// light or dark, as macOS is: background, text and the 16 colors (the window and the palette panel)
    func paint() {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let t = dark ? Theme.dark : Theme.light
        for view in [term, paletteTerm].compactMap({ $0 }) {
            view.installColors(t.ansi.map(termColor))
            view.nativeBackgroundColor = color(t.bg)
            view.nativeForegroundColor = color(t.fg)
            view.caretColor = color(t.cursor)
            view.selectedTextBackgroundColor = color(t.selection)
        }
        window.backgroundColor = color(t.bg)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        panel?.contentView?.layer?.backgroundColor = color(t.bg).cgColor
        panel?.appearance = window.appearance
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

    /// `zidev keys` (and how to start the palette), asked again while it answers nothing (it fails while zidev
    /// itself is being changed): cmd-k and the other keys do not stay dead until the app restarts
    func reloadKeys(tries: Int) {
        DispatchQueue.global().async {
            let keys = loadKeys()
            let argv = loadPaletteArgv()
            DispatchQueue.main.async {
                self.term.keys = keys
                self.paletteArgv = argv
                if keys.isEmpty && tries > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.reloadKeys(tries: tries - 1) }
                }
            }
        }
    }

    func applicationDidBecomeActive(_ n: Notification) {
        if term?.keys.isEmpty == true { reloadKeys(tries: 1) }
    }

    // ZI79: the app keeps running without its window, so the clipboard and the keys keep working.
    // Closing the window hides it; zidev stays in it
    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { false }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender !== window { return true }
        window.orderOut(nil)
        return false
    }

    /// a click on the Dock icon (or opening the app again) shows the window
    func applicationShouldHandleReopen(_ a: NSApplication, hasVisibleWindows: Bool) -> Bool {
        show()
        return false
    }

    // zidev ended (detached, or its server stopped): the sessions keep running; the window hides, and zidev
    // starts again when it shows. The palette ended (picked, or esc): its panel goes
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        if source === term {
            zidevEnded = true
            window.orderOut(nil)
        } else if source === paletteTerm {
            closePalette()
        }
    }
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
