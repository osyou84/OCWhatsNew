//
//  OCWhatsNew.swift
//  OCWhatsNew
//

import Foundation

/// `[OCWhatsNewItem]` を対象にバージョン比較を行うユーティリティ。
///
/// アプリ側は自身のカタログ（`[OCWhatsNewItem]`）と、既読バージョンを保持する
/// `OCWhatsNewVersionStoring` を組み合わせて、次のように使う。
///
/// ```swift
/// let store = OCUserDefaultsWhatsNewVersionStore()
/// // 初回起動（インストール直後）のユーザーには表示しない
/// let unseen = OCWhatsNew.itemsToPresent(in: myAppWhatsNewItems, store: store, showOnFirstLaunch: false)
/// if !unseen.isEmpty {
///     // OCWhatsNewView を表示する
/// }
/// ```
public enum OCWhatsNew {
    /// カタログ内の最新バージョンを返す（バージョン文字列を数値として比較する）
    public static func latestVersion(in items: [OCWhatsNewItem]) -> String? {
        items
            .map(\.version)
            .max { $0.compare($1, options: .numeric) == .orderedAscending }
    }

    /// `lastSeenVersion` より新しいページをバージョン昇順で返す。
    ///
    /// - Parameters:
    ///   - items: What's New カタログ
    ///   - lastSeenVersion: 最後に表示済みのバージョン。`nil` は「まだ一度も見せていない」＝初回起動を表す
    ///   - showOnFirstLaunch: 初回起動（`lastSeenVersion` が `nil`）のときに全件を未読として返すかどうか。
    ///     `false` にするとインストール直後のユーザーには何も表示されない（空配列を返す）。既定は `true`
    public static func unseenItems(
        in items: [OCWhatsNewItem],
        lastSeenVersion: String?,
        showOnFirstLaunch: Bool = true
    ) -> [OCWhatsNewItem] {
        if lastSeenVersion == nil && !showOnFirstLaunch {
            return []
        }
        return items
            .filter { item in
                guard let lastSeenVersion else { return true }
                return item.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
            }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
    }

    /// `store` の既読バージョンを踏まえて、いま表示すべき未読ページを返す。
    ///
    /// `showOnFirstLaunch` が `false` の場合、初回起動（`store.lastSeenVersion` が `nil`）では
    /// 何も表示せず、**その時点のカタログ最新バージョンを既読として `store` に記録する**。
    /// これによりインストール直後は静かにしておきつつ、次回以降のアップデートでは
    /// 新しく追加された機能だけが正しく表示されるようになる。
    ///
    /// - Parameters:
    ///   - items: What's New カタログ
    ///   - store: 既読バージョンの保存先
    ///   - showOnFirstLaunch: 初回起動のユーザーにも表示するかどうか。既定は `false`（表示しない）
    /// - Returns: 表示すべき未読ページ（バージョン昇順）。表示不要なら空配列
    @discardableResult
    public static func itemsToPresent(
        in items: [OCWhatsNewItem],
        store: OCWhatsNewVersionStoring,
        showOnFirstLaunch: Bool = false
    ) -> [OCWhatsNewItem] {
        if store.lastSeenVersion == nil && !showOnFirstLaunch {
            // 初回起動: 何も見せず、現時点の最新を既読として記録しておく
            store.lastSeenVersion = latestVersion(in: items)
            return []
        }
        return unseenItems(in: items, lastSeenVersion: store.lastSeenVersion)
    }
}
