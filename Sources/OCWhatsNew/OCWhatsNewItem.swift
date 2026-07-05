//
//  OCWhatsNewItem.swift
//  OCWhatsNew
//

import Foundation

/// What's New 1ページ分の内容。バージョン単位で1つ以上のページを定義する。
///
/// `title` / `detail` / `note` は `LocalizedStringKey` に変換して表示されるため、
/// アプリ側の `Localizable.strings` に定義したキーをそのまま渡せる。
public struct OCWhatsNewItem: Identifiable, Sendable {
    public let id: UUID
    /// このページを導入したアプリバージョン（例: "2.8.0"）。数値として比較されるため "1.2.0" のような形式にする
    public let version: String
    /// SF Symbols のシステムアイコン名
    public let iconSystemName: String
    /// ローカライズキー、または表示したい文字列そのもの
    public let title: String
    /// ローカライズキー、または表示したい文字列そのもの
    public let detail: String
    /// 補足説明。本文より控えめに表示する。ローカライズキー、または表示したい文字列そのもの
    public let note: String?
    /// 機能のON/OFFをその場で選ばせたい場合に指定する
    public let toggle: OCWhatsNewToggle?

    public init(
        id: UUID = UUID(),
        version: String,
        iconSystemName: String,
        title: String,
        detail: String,
        note: String? = nil,
        toggle: OCWhatsNewToggle? = nil
    ) {
        self.id = id
        self.version = version
        self.iconSystemName = iconSystemName
        self.title = title
        self.detail = detail
        self.note = note
        self.toggle = toggle
    }
}

/// What's New ページに紐づく設定トグル。シート確定時に `set` が呼ばれる
public struct OCWhatsNewToggle: Sendable {
    /// ローカライズキー、または表示したい文字列そのもの
    public let title: String
    public let get: @Sendable () -> Bool
    public let set: @Sendable (Bool) -> Void

    public init(
        title: String,
        get: @escaping @Sendable () -> Bool,
        set: @escaping @Sendable (Bool) -> Void
    ) {
        self.title = title
        self.get = get
        self.set = set
    }
}
