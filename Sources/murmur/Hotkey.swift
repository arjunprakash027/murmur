import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggle = Self("toggle", default: .init(.space, modifiers: [.control, .option]))
}

final class Hotkey {
    static func install(onToggle: @escaping () -> Void) {
        KeyboardShortcuts.onKeyDown(for: .toggle, action: onToggle)
    }
}
