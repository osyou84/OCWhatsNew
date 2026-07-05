//
//  OCWhatsNewViewModel.swift
//  OCWhatsNew
//

// OCWhatsNewView はページ送り TabView (.page スタイル) を使用しており、
// このスタイルは AppKit (macOS) には存在しないため、対応プラットフォームのみでビルドする
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

import SwiftUI

@MainActor
final class OCWhatsNewViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var toggleStates: [UUID: Bool] = [:]
    private var didPrepare = false

    /// items のトグル初期状態を取り込む（初回のみ）。
    ///
    /// items 自体は View 側が `let` として保持する。ViewModel（`@StateObject`）に items を
    /// 持たせると、View が空 items で先に評価された場合に初期値がキャプチャされ、後から
    /// items を渡しても反映されない（＝ページが空になる）ため、ここでは可変な UI 状態だけを持つ
    func prepare(items: [OCWhatsNewItem]) {
        guard !didPrepare else { return }
        didPrepare = true
        var states: [UUID: Bool] = [:]
        for item in items {
            if let toggle = item.toggle {
                states[item.id] = toggle.get()
            }
        }
        toggleStates = states
    }

    func isLastPage(pageCount: Int) -> Bool {
        currentIndex >= pageCount - 1
    }

    func toggleBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { [weak self] in self?.toggleStates[id] ?? false },
            set: { [weak self] in self?.toggleStates[id] = $0 }
        )
    }

    func advance(pageCount: Int) {
        guard !isLastPage(pageCount: pageCount) else { return }
        currentIndex += 1
    }

    /// シート確定時に各ページのトグル選択を保存し、最新バージョンを既読にする
    func commit(items: [OCWhatsNewItem], store: OCWhatsNewVersionStoring) {
        for item in items {
            if let toggle = item.toggle, let value = toggleStates[item.id] {
                toggle.set(value)
            }
        }
        // items が空のときは latestVersion が nil になり既読が消える（＝毎回再表示）ため、
        // 既読バージョンは更新できるとき（＝最新版が求まるとき）だけ書き換える
        if let latest = OCWhatsNew.latestVersion(in: items) {
            store.lastSeenVersion = latest
        }
    }
}

#endif
