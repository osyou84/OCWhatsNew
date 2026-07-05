//
//  OCWhatsNew.swift
//  OCWhatsNew
//

import Foundation

/// `[WhatsNewItem]` を対象にバージョン比較を行うユーティリティ。
///
/// アプリ側は自身のカタログ（`[WhatsNewItem]`）と、既読バージョンを保持する
/// `WhatsNewVersionStoring` を組み合わせて、次のように使う。
///
/// ```swift
/// let store = UserDefaultsWhatsNewVersionStore()
/// let unseen = OCWhatsNew.unseenItems(in: myAppWhatsNewItems, lastSeenVersion: store.lastSeenVersion)
/// if !unseen.isEmpty {
///     // WhatsNewView を表示する
/// }
/// ```
public enum OCWhatsNew {
    /// カタログ内の最新バージョンを返す（バージョン文字列を数値として比較する）
    public static func latestVersion(in items: [WhatsNewItem]) -> String? {
        items
            .map(\.version)
            .max { $0.compare($1, options: .numeric) == .orderedAscending }
    }

    /// `lastSeenVersion` より新しいページをバージョン昇順で返す。
    /// `lastSeenVersion` が `nil` の場合は全件を未読として返す
    public static func unseenItems(in items: [WhatsNewItem], lastSeenVersion: String?) -> [WhatsNewItem] {
        items
            .filter { item in
                guard let lastSeenVersion else { return true }
                return item.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
            }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
    }
}
