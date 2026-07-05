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
/// let unseen = OCWhatsNew.unseenItems(in: myAppWhatsNewItems, lastSeenVersion: store.lastSeenVersion)
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
    /// `lastSeenVersion` が `nil` の場合は全件を未読として返す
    public static func unseenItems(in items: [OCWhatsNewItem], lastSeenVersion: String?) -> [OCWhatsNewItem] {
        items
            .filter { item in
                guard let lastSeenVersion else { return true }
                return item.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
            }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
    }
}
