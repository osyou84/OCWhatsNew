//
//  OCWhatsNew.swift
//  OCWhatsNew
//

import Foundation

/// What's New の表示判定と既読管理を担うエントリポイント。
///
/// アプリ側はカタログを一度登録し、表示したい画面に `whatsNewSheet` モディファイアを
/// 付けるだけでよい。既読バージョンの保存・未読判定・表示タイミングはライブラリが処理する。
///
/// ```swift
/// // 起動時に一度（App の init など）
/// OCWhatsNew.configure(items: myAppWhatsNewItems)
///
/// // 表示したい画面に付ける
/// MainView()
///     .whatsNewSheet(title: "What's New")
/// ```
public enum OCWhatsNew {
    // MARK: - 登録済みカタログ（configure で設定）

    /// アプリ側から登録された What's New カタログ
    @MainActor private(set) static var registeredItems: [OCWhatsNewItem] = []
    /// 既読バージョンの保存先。既定は UserDefaults
    @MainActor private(set) static var store: OCWhatsNewVersionStoring = OCUserDefaultsWhatsNewVersionStore()
    /// 既読が未記録の起動を「アップデート」として扱うかどうか（configure で設定）
    @MainActor private(set) static var treatFirstLaunchAsUpdate = false

    /// カタログを登録する。アプリ起動時に一度呼ぶ。
    ///
    /// - Parameters:
    ///   - items: What's New カタログ（全バージョン分）
    ///   - store: 既読バージョンの保存先。通常は既定のままでよい
    ///   - treatFirstLaunchAsUpdate: 既読が未記録（通常は初回起動を意味する）のとき、
    ///     初回起動ではなく「What's New 導入前のバージョンからのアップデート」として扱い、
    ///     カタログ全件を未読として表示するかどうか。既定は `false`。
    ///
    ///     ライブラリを初めて組み込んだバージョンでは、アップデートユーザーにも既読記録がないため
    ///     新規インストールと区別できず、黙って既読化されてしまう。アプリ側が旧バージョンの
    ///     痕跡（既存の UserDefaults キーなど）から既存ユーザーだと判定できる場合に `true` を渡す。
    ///
    ///     ```swift
    ///     // 旧バージョンが必ず書き込んでいたキーの有無で既存ユーザーを判定する例
    ///     OCWhatsNew.configure(
    ///         items: MyAppWhatsNewCatalog.allItems,
    ///         treatFirstLaunchAsUpdate: UserDefaults.standard.object(forKey: "appLaunchCount") != nil
    ///     )
    ///     ```
    @MainActor
    public static func configure(
        items: [OCWhatsNewItem],
        store: OCWhatsNewVersionStoring = OCUserDefaultsWhatsNewVersionStore(),
        treatFirstLaunchAsUpdate: Bool = false
    ) {
        registeredItems = items
        self.store = store
        self.treatFirstLaunchAsUpdate = treatFirstLaunchAsUpdate
    }

    /// 既読バージョンをリセットする（デバッグ用）。次回表示タイミングで全件が未読になる。
    /// `nil` は「初回起動」を意味し黙って既読化されてしまうため、全件より古い "0.0.0" を記録する
    @MainActor
    public static func resetSeenVersion() {
        store.lastSeenVersion = "0.0.0"
    }

    /// いま表示すべき未読ページを登録済みカタログから返す（`whatsNewSheet` の内部用）。
    /// 初回起動（既読が未記録）の場合は何も表示せず、最新バージョンを既読として記録する
    @MainActor
    static func takeItemsToPresent() -> [OCWhatsNewItem] {
        itemsToPresent(
            in: registeredItems,
            store: store,
            showOnFirstLaunch: false,
            treatFirstLaunchAsUpdate: treatFirstLaunchAsUpdate
        )
    }

    /// 表示済みページを既読として記録する（シート確定時の内部用）。
    /// items が空のときは latestVersion が nil になり既読が消えてしまうため、書き換えない
    @MainActor
    static func markAsSeen(_ items: [OCWhatsNewItem]) {
        if let latest = latestVersion(in: items) {
            store.lastSeenVersion = latest
        }
    }

    // MARK: - バージョン比較ユーティリティ

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
    ///   - treatFirstLaunchAsUpdate: 既読が未記録のとき、初回起動ではなく
    ///     「What's New 導入前のバージョンからのアップデート」として扱い全件を未読で返すかどうか。
    ///     既読化はここでは行わず、シート確定時（`markAsSeen`）に委ねる。既定は `false`
    /// - Returns: 表示すべき未読ページ（バージョン昇順）。表示不要なら空配列
    @discardableResult
    public static func itemsToPresent(
        in items: [OCWhatsNewItem],
        store: OCWhatsNewVersionStoring,
        showOnFirstLaunch: Bool = false,
        treatFirstLaunchAsUpdate: Bool = false
    ) -> [OCWhatsNewItem] {
        if store.lastSeenVersion == nil && !showOnFirstLaunch {
            if treatFirstLaunchAsUpdate {
                // 導入前バージョンからのアップデート: 全件を未読として表示する
                return unseenItems(in: items, lastSeenVersion: nil)
            }
            // 初回起動: 何も見せず、現時点の最新を既読として記録しておく
            store.lastSeenVersion = latestVersion(in: items)
            return []
        }
        return unseenItems(in: items, lastSeenVersion: store.lastSeenVersion)
    }
}
