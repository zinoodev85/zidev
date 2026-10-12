// zidev.app: a window of its own for zidev (a terminal running `zidev`), with its own Dock icon.
// The cmd / alt keys zidev knows (`zidev keys`) go straight to it; the rest stay the app's (cmd-q, cmd-v).
// cmd-click on a `! command` Claude suggests runs it.
import AppKit
import SwiftTerm

let shell = "/bin/zsh"

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

struct Theme {
    let bg: UInt32, fg: UInt32, ansi: [UInt32]
    static let dark = Theme(bg: 0x15171c, fg: 0xd4d7dd, ansi: [
        0x14191e, 0xe0675a, 0x5fc96f, 0xd9c45a, 0x6c8cf0, 0xc678dd, 0x56c8d4, 0xc7c9cd,
        0x686d76, 0xf08a7e, 0x7fe08f, 0xece17a, 0x93acf7, 0xe09ef0, 0x7fe3ee, 0xffffff])
    static let light = Theme(bg: 0xfafafa, fg: 0x1a1c20, ansi: [
        0x14191e, 0xb43c2a, 0x188a2c, 0x9a7d00, 0x2744c7, 0xa035a0, 0x00838a, 0xc7c7c7,
        0x686868, 0xc8503e, 0x24a33c, 0xb39200, 0x4a64d8, 0xb84ab8, 0x00a0a8, 0xffffff])
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
        // the cell size as SwiftTerm measures it
        let w = font.advancement(forGlyph: font.glyph(withName: "W")).width
        let h = ceil(font.ascender - font.descender + font.leading)
        let col = Int(p.x / w) + 1, row = Int((bounds.height - p.y) / h) + 1
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
        term = ZidevView(frame: NSRect(x: 0, y: 0, width: 1200, height: 760))
        term.processDelegate = self
        term.optionAsMetaKey = true
        term.font = NSFont(name: "MesloLGS-NF-Regular", size: 14) ?? NSFont(name: "SF Mono", size: 13)
            ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        window = NSWindow(contentRect: term.frame, styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "zidev"
        window.titlebarAppearsTransparent = true
        window.contentView = term
        window.delegate = self
        window.setFrameAutosaveName("zidev")
        if !window.setFrameUsingName("zidev") { window.center() }
        paint()
        look = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in self?.paint() }
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(term)
        keyWatch = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            self?.term.zidevKey(e) == true ? nil : e  // before the menu and the terminal see it
        }
        clickWatch = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] e in
            self?.term.cmdClick(e) == true ? nil : e
        }
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

    /// light or dark, as macOS is: background, text and the 16 colors
    func paint() {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let t = dark ? Theme.dark : Theme.light
        term.installColors(t.ansi.map(termColor))
        term.nativeBackgroundColor = color(t.bg)
        term.nativeForegroundColor = color(t.fg)
        term.caretColor = color(t.fg)
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
