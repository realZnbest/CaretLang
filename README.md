# CaretLang

A tiny macOS menu-less app that keeps a **flag + sample letters** of your current input source pinned right next to the text cursor — so you stop typing `ทำหยที` when you meant `hello`.

| Thai | English | Japanese |
|---|---|---|
| 🇹🇭 กขค | 🇺🇸 ABC | 🇯🇵 あいう |

*(the app draws real SVG flag icons, not emoji)*

## Features

- Stays visible **the whole time a text field is focused**, following the caret as you type — not just a brief flash when you switch.
- Ignores the mouse. Disappears when you leave the text field.
- **Every language macOS supports**: the flag comes from the input source's language (via `Locale` region inference), with overrides for regional layouts (British → 🇬🇧, Canadian → 🇨🇦, Swiss → 🇨🇭 …). Sample letters come from the script (Latin `ABC`, Cyrillic `АБВ`, Arabic `ابت`, Devanagari `कखग`, …).
- **Terminals** (Ghostty, etc.) don't expose the caret position, so there the badge sits in the bottom-left corner of the terminal view.
- Chromium/Electron apps get their accessibility tree switched on automatically so the caret can be found.

## Install

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/realZnbest/CaretLang.git
cd CaretLang
./build.sh --install
```

On first launch macOS asks for **Accessibility** permission (System Settings → Privacy & Security → Accessibility → enable CaretLang). The badge appears as soon as it's granted.

To start it at login: System Settings → General → Login Items → `+` → `~/Applications/CaretLang.app`.

## Uninstall

```bash
pkill -x CaretLang; rm -rf ~/Applications/CaretLang.app
```

## How it works

Every 80 ms it asks the Accessibility API for the focused element's selected text range and `AXBoundsForRange`, then moves a borderless, click-through panel under the caret. The current input source comes from `TISCopyCurrentKeyboardInputSource`.

## Credits

Flag icons from [flag-icons](https://github.com/lipis/flag-icons) by Panayiotis Lipiridis (MIT) — see `Resources/flags/LICENSE-flag-icons`.

## License

MIT
