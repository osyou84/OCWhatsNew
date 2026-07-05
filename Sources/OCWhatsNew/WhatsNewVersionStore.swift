//
//  WhatsNewVersionStore.swift
//  OCWhatsNew
//

import Foundation

/// 「最後に見せたWhat's Newのバージョン」を永続化する場所を抽象化するプロトコル。
///
/// 既に自前の UserDefaults ラッパーを持っているアプリは、このプロトコルに準拠させることで
/// そのまま `WhatsNewView` に差し込める。
public protocol WhatsNewVersionStoring: AnyObject, Sendable {
    var lastSeenVersion: String? { get set }
}

/// `WhatsNewVersionStoring` の既定実装。UserDefaults にバージョン文字列を保存する
public final class UserDefaultsWhatsNewVersionStore: WhatsNewVersionStoring, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard, key: String = "OCWhatsNew.lastSeenVersion") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public var lastSeenVersion: String? {
        get { userDefaults.string(forKey: key) }
        set { userDefaults.set(newValue, forKey: key) }
    }
}
