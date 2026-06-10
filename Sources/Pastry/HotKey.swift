import Carbon

/// Global hotkey via Carbon — works without accessibility permission.
final class HotKey {
    var handler: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().handler?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
        let hotKeyID = EventHotKeyID(signature: OSType(0x4350_5354), id: 1) // 'CPST'
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
