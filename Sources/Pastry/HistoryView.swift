import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @ObservedObject var vm: PanelViewModel
    @ObservedObject private var themeStore = ThemeStore.shared
    let onPaste: (ClipItem) -> Void
    let onTogglePin: (ClipItem) -> Void
    let onDelete: (ClipItem) -> Void
    let onClearAll: () -> Void

    @State private var showingThemePicker = false

    private var theme: PastryTheme { themeStore.current }

    var body: some View {
        VStack(spacing: 0) {
            header
            if showingThemePicker {
                themePicker
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Divider().opacity(0.5)
            if store.items.isEmpty {
                emptyState
            } else {
                list
            }
            Divider().opacity(0.5)
            footer
        }
        .animation(.easeInOut(duration: 0.18), value: showingThemePicker)
        .frame(width: PanelController.panelSize.width, height: PanelController.panelSize.height)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    private var hasUnpinned: Bool { store.items.contains { !$0.pinned } }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.gradient)
            Text("Pastry")
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Spacer()
            if !store.items.isEmpty {
                Text("\(store.items.count) item\(store.items.count == 1 ? "" : "s")")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            Button(action: onClearAll) {
                Text("Clear All")
                    .font(.system(size: 10.5, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .foregroundColor(hasUnpinned ? .primary : .secondary)
            .disabled(!hasUnpinned)
            .help("Remove everything except pinned items")

            Button {
                showingThemePicker.toggle()
            } label: {
                Image(systemName: showingThemePicker ? "xmark.circle.fill" : "paintpalette")
                    .font(.system(size: 12))
                    .foregroundColor(showingThemePicker ? theme.accent : .secondary)
            }
            .buttonStyle(.plain)
            .help("Change color scheme")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var themePicker: some View {
        HStack(spacing: 10) {
            ForEach(PastryTheme.allCases) { t in
                Button {
                    themeStore.current = t
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(t.gradient)
                                .frame(width: 28, height: 28)
                            if themeStore.current == t {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(themeStore.current == t
                                              ? t.accent : Color.primary.opacity(0.15),
                                              lineWidth: themeStore.current == t ? 2 : 1)
                        )
                        Text(t.rawValue)
                            .font(.system(size: 9))
                            .foregroundColor(themeStore.current == t ? t.accent : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.04))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(theme.gradient)
            Text("Nothing here yet")
                .font(.system(size: 13, weight: .semibold))
            Text("Copy some text or images and they'll\nshow up here, ready to paste anytime.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                        ItemRow(
                            item: item,
                            selected: index == vm.selection,
                            theme: theme,
                            onPaste: { onPaste(item) },
                            onTogglePin: { onTogglePin(item) },
                            onDelete: { onDelete(item) }
                        )
                        .id(item.id)
                    }
                }
                .padding(8)
            }
            .onChange(of: vm.selection) { newValue in
                guard store.items.indices.contains(newValue) else { return }
                proxy.scrollTo(store.items[newValue].id)
            }
            .onChange(of: vm.presentedAt) { _ in
                if let first = store.items.first {
                    proxy.scrollTo(first.id)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            KeyHint(key: "↑↓", label: "Select")
            KeyHint(key: "↩", label: "Paste")
            KeyHint(key: "P", label: "Pin")
            KeyHint(key: "⌫", label: "Delete")
            KeyHint(key: "esc", label: "Close")
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
    }
}

private struct KeyHint: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

private struct ItemRow: View {
    let item: ClipItem
    let selected: Bool
    let theme: PastryTheme
    let onPaste: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    private static let timeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            badge
            VStack(alignment: .leading, spacing: 3) {
                preview
                caption
            }
            Spacer(minLength: 4)
            if hovering || selected || item.pinned {
                actions
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(selected
                      ? theme.accent.opacity(0.16)
                      : hovering ? Color.primary.opacity(0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(selected ? theme.accent.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onPaste)
        .onHover { hovering = $0 }
    }

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(badgeColor.opacity(0.15))
            Image(systemName: badgeIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeColor)
        }
        .frame(width: 26, height: 26)
    }

    private var badgeIcon: String {
        switch item.content {
        case .text:  return "text.alignleft"
        case .image: return "photo"
        }
    }

    private var badgeColor: Color {
        switch item.content {
        case .text:  return theme.textBadgeColor
        case .image: return theme.imageBadgeColor
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.content {
        case .text(let s):
            Text(String(s.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300)))
                .font(.system(size: 12))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Image")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var caption: some View {
        HStack(spacing: 4) {
            if item.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundColor(theme.accent)
            }
            Text(timeText)
            Text("·")
            Text(metaText)
        }
        .font(.system(size: 10))
        .foregroundColor(.secondary)
    }

    private var timeText: String {
        let elapsed = -item.copiedAt.timeIntervalSinceNow
        if elapsed < 60 { return "Just now" }
        return Self.timeFormatter.localizedString(for: item.copiedAt, relativeTo: Date())
    }

    private var metaText: String {
        switch item.content {
        case .text(let s):
            return "\(s.count) character\(s.count == 1 ? "" : "s")"
        case .image(let data):
            if let rep = NSBitmapImageRep(data: data) {
                return "\(rep.pixelsWide) × \(rep.pixelsHigh)"
            }
            return "Image"
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button(action: onTogglePin) {
                Image(systemName: item.pinned ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundColor(item.pinned ? theme.accent : .secondary)
            }
            .buttonStyle(.plain)
            .help(item.pinned ? "Unpin" : "Pin")
            if hovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
