# OCWhatsNew

[![GitHub release](https://img.shields.io/github/v/release/osyou84/OCWhatsNew)](https://github.com/osyou84/OCWhatsNew/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](https://github.com/osyou84/OCWhatsNew/blob/master/LICENSE)

アプリのアップデート後に新機能を紹介する「What's New」画面を、少ないコードで実装するための SwiftUI 製 Swift Package です。

カタログを一度登録して View にモディファイアを付けるだけで、**表示するかどうかの判定・表示タイミング・既読バージョンの永続化まで、すべてライブラリ側が自動で処理します。**

- カタログ登録 + モディファイア1行で導入完了（表示判定・既読管理は自動）
- バージョンをまたいだページ送り（TabView + ページングスタイル）
- ページ単位のON/OFFトグル（機能フラグの初回案内などに）
- インストール直後のユーザーには表示せず、次回アップデート分から案内
- 色・フォント・文言をすべてアプリ側からカスタマイズ可能

## 動作環境

- iOS 18+
- tvOS 18+
- watchOS 11+
- visionOS 2+
- macOS 15+（`TabView` のページングスタイルが存在しないため、UIを持たずバージョン比較ロジックのみ利用可能）
- Swift 6+

## インストール

最新バージョンは上記バッジから確認してください。

### Swift Package Manager

`Package.swift` に以下を追加してください。

```swift
dependencies: [
    .package(url: "https://github.com/osyou84/OCWhatsNew.git", from: "<version>")
]
```

または Xcode の **File > Add Package Dependencies...** からリポジトリ URL を入力してください。

```
https://github.com/osyou84/OCWhatsNew
```

## 使い方

### 1. What's New の内容をアプリ側で定義する

`OCWhatsNewItem` の配列として、アプリ内のどこか（例: `enum MyAppWhatsNewCatalog`）に持たせます。
新しいお知らせを追加するときは、この配列に1件追記するだけです。

```swift
import OCWhatsNew

enum MyAppWhatsNewCatalog {
    static let allItems: [OCWhatsNewItem] = [
        OCWhatsNewItem(
            version: "2.8.0",              // このページを導入したアプリバージョン
            iconSystemName: "flag.checkered",
            title: "ghost_race_title",     // Localizable.strings のキーでも生文字列でもOK
            detail: "ghost_race_detail",
            note: "ghost_race_note",       // 任意
            toggle: OCWhatsNewToggle(         // 任意。その場で機能のON/OFFを選ばせたい場合
                title: "ghost_race_toggle",
                get: { AppDefaults.isGhostEnabled },
                set: { AppDefaults.isGhostEnabled = $0 }
            )
        )
    ]
}
```

### 2. 起動時にカタログを登録する

アプリ起動時に一度だけ `OCWhatsNew.configure(items:)` を呼びます。

```swift
import OCWhatsNew

@main
struct MyApp: App {
    init() {
        OCWhatsNew.configure(items: MyAppWhatsNewCatalog.allItems)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
```

### 3. 表示したい画面に `whatsNewSheet` を付ける

これだけで、その View の表示時に未読のお知らせがあれば自動でシート表示されます。
シートの出し分け・既読の記録はすべてライブラリが処理するため、アプリ側で `@State` や
`.sheet` を管理する必要はありません。

```swift
import OCWhatsNew

struct HomeView: View {
    var body: some View {
        Text("Home")
            .whatsNewSheet(
                title: "whats_new_title",       // Localizable.strings のキーをそのまま渡せる
                nextButton: "whats_new_next",
                startButton: "whats_new_start"
            )
    }
}
```

シート確定時（最終ページでスタートボタンをタップしたタイミング）には

1. 各ページのトグルに設定された `set` クロージャを呼んで選択内容を保存し、
2. カタログ内の最新バージョンを既読として記録します。

これにより、次回起動時は同じお知らせが再表示されません。

### 表示タイミングの仕様

- **初回起動（インストール直後）**: 何も表示せず、その時点のカタログ最新バージョンを既読として記録します。
  インストール直後は静かにしておきつつ、次回以降のアップデートでは **新しく追加された機能だけ** が表示されます。
- **アップデート後**: 既読バージョンより新しいページだけを、バージョン昇順のページ送りで表示します。
- **未読なし**: 何も表示しません。

## カスタマイズ

### 見た目 (`OCWhatsNewStyle`)

```swift
.whatsNewSheet(
    title: "whats_new_title",
    nextButton: "whats_new_next",
    startButton: "whats_new_start",
    style: OCWhatsNewStyle(
        background: AnyShapeStyle(LinearGradient(colors: [.main, .sub], startPoint: .top, endPoint: .bottom)),
        foregroundColor: .white,
        accentColor: .main,
        titleFont: .hyakumasuTitle.bold(),
        headlineFont: .hyakumasuHeadline.bold(),
        bodyFont: .hyakumasuBody,
        captionFont: .hyakumasuCaption
    )
)
```

指定しなかったプロパティは `.accentColor` ベースの標準的な外観になります。

### 既読バージョンの保存先 (`OCWhatsNewVersionStoring`)

既定では `UserDefaults.standard` に保存しますが、既に自前の永続化層を持っている場合は
プロトコルに準拠させて `configure` で差し替えられます。

```swift
final class AppDefaultsWhatsNewVersionStore: OCWhatsNewVersionStoring {
    var lastSeenVersion: String? {
        get { AppDefaults.lastSeenWhatsNewVersion }
        set { AppDefaults.lastSeenWhatsNewVersion = newValue }
    }
}

OCWhatsNew.configure(
    items: MyAppWhatsNewCatalog.allItems,
    store: AppDefaultsWhatsNewVersionStore()
)
```

## デバッグ

既読状態をリセットすると、次の表示タイミングで全ページが未読として再表示されます。
デバッグメニューなどから呼んでください。

```swift
OCWhatsNew.resetSeenVersion()
```

## 低レベルAPI

表示判定を自前で組み立てたい場合は、`store` に依存しない純粋関数も利用できます。

```swift
// カタログ内の最新バージョン
OCWhatsNew.latestVersion(in: items)

// lastSeenVersion より新しいページ（バージョン昇順）
OCWhatsNew.unseenItems(in: items, lastSeenVersion: "1.0.0")

// store の既読を踏まえた表示対象（初回起動の既読化も行う）
OCWhatsNew.itemsToPresent(in: items, store: store, showOnFirstLaunch: false)
```

## バージョン比較の仕様

`version` は `"2.10.0"` のような文字列を `String.compare(_:options: .numeric)` で比較します。
そのため `"1.9.0"` より `"1.10.0"` の方が新しいと正しく判定されます（単純な文字列比較では逆転してしまうケース）。

## テスト

```sh
swift test
```

`OCWhatsNewView` / `OCWhatsNewViewModel` は iOS / tvOS / watchOS / visionOS 専用のため、
これらのUI関連テストは iOS シミュレータなど対応プラットフォーム上でのみ実行されます
（`xcodebuild -scheme OCWhatsNew -destination 'platform=iOS Simulator,name=<Simulator名>' test`）。
バージョン比較ロジック (`OCWhatsNew`, `OCUserDefaultsWhatsNewVersionStore`) のテストは macOS 上でも実行できます。

## ライセンス

[MIT](https://github.com/osyou84/OCWhatsNew/blob/master/LICENSE)
