//
//  WhatsNewViewModel.swift
//  OCWhatsNew
//

// WhatsNewView はページ送り TabView (.page スタイル) を使用しており、
// このスタイルは AppKit (macOS) には存在しないため、対応プラットフォームのみでビルドする
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

import SwiftUI

@MainActor
final class WhatsNewViewModel: ObservableObject {
    let items: [WhatsNewItem]
    @Published var currentIndex: Int = 0
    @Published var toggleStates: [UUID: Bool]

    init(items: [WhatsNewItem]) {
        self.items = items
        var states: [UUID: Bool] = [:]
        for item in items {
            if let toggle = item.toggle {
                states[item.id] = toggle.get()
            }
        }
        toggleStates = states
    }

    var isLastPage: Bool {
        currentIndex >= items.count - 1
    }

    func toggleBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { [weak self] in self?.toggleStates[id] ?? false },
            set: { [weak self] in self?.toggleStates[id] = $0 }
        )
    }

    func advance() {
        guard !isLastPage else { return }
        currentIndex += 1
    }

    /// シート確定時に各ページのトグル選択を保存し、最新バージョンを既読にする
    func commit(store: WhatsNewVersionStoring) {
        for item in items {
            if let toggle = item.toggle, let value = toggleStates[item.id] {
                toggle.set(value)
            }
        }
        store.lastSeenVersion = OCWhatsNew.latestVersion(in: items)
    }
}

#endif
