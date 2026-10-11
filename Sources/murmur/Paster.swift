import AppKit
import ApplicationServices

// Manual tests (need Accessibility permission for the murmur app, and a human):
// 1. No permission: paste() shows the system prompt and pastes nothing.
// 2. TextEdit / Notes / browser text field: text appears at the cursor; previous clipboard
//    (copy "abc" first, also try an image or file) is back after ~200 ms.
// 3. Copy something else within 200 ms of a paste: your new copy must NOT be overwritten.
// 4. Clipboard-history tools (Maccy, Raycast) must not record the dictated text.
// 5. Non-editable focus (Finder, no field): no crash; text is set via AX if possible.
// 6. Terminal and an Electron app (VS Code, Slack): text pastes.
final class Paster {
    static func paste(_ text: String) {
        guard AXIsProcessTrusted() else {
            _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
            return
        }

        let pb = NSPasteboard.general
        let snapshot: [[(NSPasteboard.PasteboardType, Data)]] = (pb.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }

        pb.clearContents()
        pb.setString(text, forType: .string)
        for name in ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType"] {
            pb.setData(Data(), forType: NSPasteboard.PasteboardType(name))
        }
        let ourCount = pb.changeCount

        if !(isEditable() && postCmdV()) && !setSelectedText(text) {
            _ = postCmdV()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard pb.changeCount == ourCount else { return }
            pb.clearContents()
            pb.writeObjects(snapshot.map { entries in
                let item = NSPasteboardItem()
                for (type, data) in entries { item.setData(data, forType: type) }
                return item
            })
        }
    }

    private static func focusedElement() -> AXUIElement? {
        var ref: CFTypeRef?
        let sys = AXUIElementCreateSystemWide()
        guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &ref) == .success,
              let ref, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return (ref as! AXUIElement)
    }

    private static func isEditable() -> Bool {
        guard let el = focusedElement() else { return false }
        var settable: DarwinBoolean = false
        return AXUIElementIsAttributeSettable(el, kAXSelectedTextAttribute as CFString, &settable) == .success
            && settable.boolValue
    }

    private static func setSelectedText(_ text: String) -> Bool {
        guard let el = focusedElement() else { return false }
        return AXUIElementSetAttributeValue(el, kAXSelectedTextAttribute as CFString, text as CFString) == .success
    }

    private static func postCmdV() -> Bool {
        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false) else { return false }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}
