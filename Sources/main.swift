// CaretLang — แสดงภาษาที่ใช้อยู่ค้างไว้ข้างเคอร์เซอร์พิมพ์ (text caret)
import Cocoa
import ApplicationServices
import Carbon
import ServiceManagement

// MARK: - ภาษา -> ธง + ตัวอย่างตัวอักษร

struct LangInfo: Equatable {
    let region: String? // รหัสประเทศ เช่น "th", "us" (ใช้หาไฟล์ธง)
    let sample: String  // เช่น "กขค", "ABC"
}

// layout ที่ภาษาเดียวกันแต่คนละประเทศ (อังกฤษแบบ British ฯลฯ)
let layoutRegionOverrides: [(String, String)] = [
    ("British", "gb"), ("Australian", "au"), ("Canadian", "ca"), ("Irish", "ie"),
    ("Swiss", "ch"), ("Austrian", "at"), ("Belgian", "be"), ("Brazilian", "br"),
    ("Portuguese", "pt"), ("Mexican", "mx"), ("LatinAmerican", "mx"), ("NewZealand", "nz"),
    ("Taiwan", "tw"), ("HongKong", "hk"), ("Cantonese", "hk"), ("Singapore", "sg"),
]

// ภาษาที่ประเทศ default ของ Locale ยังไม่ใช่ตัวที่คนส่วนใหญ่คาดหวัง
let languageRegionOverrides: [String: String] = ["ar": "sa"]

let languageSamples: [String: String] = [
    "ja": "あいう", "ko": "가나다", "zh": "中文", "vi": "ĂÂĐ", "fa": "ابپ", "ur": "ابپ",
]

let scriptSamples: [String: String] = [
    "Latn": "ABC", "Cyrl": "АБВ", "Grek": "ΑΒΓ", "Arab": "ابت", "Hebr": "אבג", "Thai": "กขค",
    "Laoo": "ກຂຄ", "Khmr": "កខគ", "Mymr": "ကခဂ", "Deva": "कखग", "Beng": "কখগ", "Taml": "அஆஇ",
    "Telu": "అఆఇ", "Knda": "ಅಆಇ", "Mlym": "അആഇ", "Gujr": "અઆઇ", "Guru": "ਅਆਇ", "Orya": "ଅଆଇ",
    "Sinh": "අආඇ", "Tibt": "ཀཁག", "Geor": "აბგ", "Armn": "աբգ", "Ethi": "ሀለሐ", "Hang": "가나다", "Kore": "가나다",
    "Jpan": "あいう", "Hans": "中文", "Hant": "中文", "Cher": "ᎠᎡᎢ", "Thaa": "ހށނ", "Mong": "ᠠᠡᠢ",
    "Tfng": "ⴰⴱⴳ", "Syrc": "ܐܒܓ", "Cans": "ᐁᐃᐅ",
]

var langCache: [String: LangInfo] = [:]

func currentLanguage() -> LangInfo {
    let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    var id = ""
    if let p = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) {
        id = Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
    }
    if let hit = langCache[id] { return hit }

    var code = "en"
    if let p = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages),
       let first = (Unmanaged<CFArray>.fromOpaque(p).takeUnretainedValue() as? [String])?.first {
        code = first
    }
    // เติม script/ประเทศที่น่าจะเป็นให้เอง เช่น "th" -> "th-Thai-TH", "en" -> "en-Latn-US"
    let full = Locale.Language(identifier: Locale.Language(identifier: code).maximalIdentifier)
    let base = full.languageCode?.identifier ?? code
    var region = languageRegionOverrides[base] ?? full.region?.identifier.lowercased()
    for (key, r) in layoutRegionOverrides where id.contains(key) { region = r; break }

    let sample = languageSamples[base]
        ?? full.script.flatMap { scriptSamples[$0.identifier] }
        ?? String(base.prefix(3)).uppercased()
    let info = LangInfo(region: region, sample: sample)
    langCache[id] = info
    return info
}

// MARK: - ธง (SVG จาก flag-icons)

var flagCache: [String: NSImage] = [:]

func flagImage(_ region: String?) -> NSImage? {
    guard let region else { return nil }
    if let img = flagCache[region] { return img }
    guard let url = Bundle.main.url(forResource: region, withExtension: "svg", subdirectory: "flags"),
          let img = NSImage(contentsOf: url) else { return nil }
    flagCache[region] = img
    return img
}

// MARK: - ป้าย

final class Badge: NSPanel {
    let flag = NSImageView(frame: NSRect(x: 6, y: 4, width: 19, height: 14))
    let label = NSTextField(labelWithString: "")
    var current: LangInfo?

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 60, height: 22),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let box = NSView(frame: contentRect(forFrameRect: frame))
        box.wantsLayer = true
        box.layer?.cornerRadius = 6
        box.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        contentView = box

        flag.imageScaling = .scaleAxesIndependently
        flag.wantsLayer = true
        flag.layer?.cornerRadius = 3
        flag.layer?.masksToBounds = true
        flag.layer?.borderWidth = 0.5
        flag.layer?.borderColor = NSColor.white.withAlphaComponent(0.35).cgColor

        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        box.addSubview(flag)
        box.addSubview(label)
    }

    func update(_ info: LangInfo) {
        guard info != current else { return }
        current = info
        let img = flagImage(info.region)
        flag.image = img
        flag.isHidden = img == nil
        label.stringValue = img == nil ? "🌐 " + info.sample : info.sample
        label.sizeToFit()
        let textX: CGFloat = flag.isHidden ? 7 : flag.frame.maxX + 5
        setContentSize(NSSize(width: textX + label.frame.width + 7, height: 22))
        label.setFrameOrigin(NSPoint(x: textX, y: (22 - label.frame.height) / 2))
    }
}

// MARK: - หาตำแหน่ง caret

func axValue<T>(_ el: AXUIElement, _ attr: String) -> T? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success else { return nil }
    return v as? T
}

func bounds(_ el: AXUIElement, loc: Int, len: Int) -> CGRect? {
    var range = CFRange(location: loc, length: len)
    guard let rv = AXValueCreate(.cfRange, &range) else { return nil }
    var out: CFTypeRef?
    guard AXUIElementCopyParameterizedAttributeValue(el, kAXBoundsForRangeParameterizedAttribute as CFString, rv, &out) == .success,
          let o = out, CFGetTypeID(o) == AXValueGetTypeID() else { return nil }
    var r = CGRect.zero
    AXValueGetValue(o as! AXValue, .cgRect, &r)
    return r.height > 0 ? r : nil
}

enum Anchor {
    case caret(CGRect)  // ตำแหน่ง caret จริง
    case corner(CGRect) // แอปไม่บอก caret (เช่น terminal) — ปักไว้มุมซ้ายล่างของช่องพิมพ์
}

// พิกัด AX: มุมบนซ้ายของจอหลักเป็น 0,0
func findAnchor() -> Anchor? {
    let sys = AXUIElementCreateSystemWide()
    guard let el: AXUIElement = axValue(sys, kAXFocusedUIElementAttribute) else { return nil }
    guard let rangeVal: AXValue = axValue(el, kAXSelectedTextRangeAttribute) else { return nil }
    var sel = CFRange()
    AXValueGetValue(rangeVal, .cfRange, &sel)

    if let r = bounds(el, loc: sel.location, len: 0) { return .caret(r) }
    if let r = bounds(el, loc: sel.location, len: 1) { return .caret(CGRect(x: r.minX, y: r.minY, width: 1, height: r.height)) }
    if sel.location > 0, let r = bounds(el, loc: sel.location - 1, len: 1) {
        return .caret(CGRect(x: r.maxX, y: r.minY, width: 1, height: r.height))
    }
    guard let posV: AXValue = axValue(el, kAXPositionAttribute), let sizeV: AXValue = axValue(el, kAXSizeAttribute) else { return nil }
    var p = CGPoint.zero, s = CGSize.zero
    AXValueGetValue(posV, .cgPoint, &p)
    AXValueGetValue(sizeV, .cgSize, &s)
    guard s.height > 0 else { return nil }
    // ช่องพิมพ์บรรทัดเดียวที่ว่างอยู่: ใช้ด้านซ้ายของช่อง
    if s.height < 60 { return .caret(CGRect(x: p.x + 4, y: p.y, width: 1, height: s.height)) }
    return .corner(CGRect(origin: p, size: s))
}

// Chrome / Electron ต้องเปิด accessibility ให้ก่อนถึงจะบอกตำแหน่ง caret
var poked = Set<pid_t>()
func pokeFrontApp() {
    guard let app = NSWorkspace.shared.frontmostApplication, !poked.contains(app.processIdentifier) else { return }
    poked.insert(app.processIdentifier)
    let el = AXUIElementCreateApplication(app.processIdentifier)
    AXUIElementSetAttributeValue(el, "AXManualAccessibility" as CFString, kCFBooleanTrue)
    AXUIElementSetAttributeValue(el, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let badge = Badge()
    var statusItem: NSStatusItem!
    let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ n: Notification) {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)

        // เปิดเองตอน login เฉพาะครั้งแรก — ถ้าผู้ใช้ปิดทีหลังจะไม่เปิดกลับให้
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "didSetUpLoginItem") {
            try? SMAppService.mainApp.register()
            defaults.set(true, forKey: "didSetUpLoginItem")
        }

        setUpMenuBar()
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in self?.tick() }
    }

    // MARK: menu bar

    func setUpMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: "CaretLang")

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "CaretLang", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Uninstall CaretLang…", action: #selector(uninstall), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit CaretLang", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc func toggleLogin() {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    // ลบ login item, สิทธิ์ Accessibility และย้ายตัวแอปไปถังขยะ แล้วปิดตัวเอง
    @objc func uninstall() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Uninstall CaretLang?"
        alert.informativeText = "This removes the login item and Accessibility permission, moves CaretLang to the Trash, and quits."
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        try? SMAppService.mainApp.unregister()
        if let id = Bundle.main.bundleIdentifier {
            let reset = Process()
            reset.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            reset.arguments = ["reset", "Accessibility", id]
            try? reset.run()
            reset.waitUntilExit()
            UserDefaults.standard.removePersistentDomain(forName: id)
        }
        try? FileManager.default.trashItem(at: Bundle.main.bundleURL, resultingItemURL: nil)
        NSApp.terminate(nil)
    }

    func tick() {
        guard AXIsProcessTrusted() else { badge.orderOut(nil); return }
        pokeFrontApp()
        guard let anchor = findAnchor(), let main = NSScreen.screens.first else { badge.orderOut(nil); return }
        badge.update(currentLanguage())
        // แปลงพิกัด AX -> Cocoa
        let h = main.frame.height, size = badge.frame.size
        switch anchor {
        case .caret(let r):
            badge.setFrameOrigin(NSPoint(x: r.maxX + 3, y: h - r.maxY - size.height - 2))
        case .corner(let r):
            badge.setFrameOrigin(NSPoint(x: r.minX + 12, y: h - r.maxY + 10))
        }
        badge.orderFrontRegardless()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
