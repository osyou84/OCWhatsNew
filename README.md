# OCWhatsNew

[![GitHub release](https://img.shields.io/github/v/release/osyou84/OCWhatsNew)](https://github.com/osyou84/OCWhatsNew/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](https://github.com/osyou84/OCWhatsNew/blob/master/LICENSE)

アプリのアップデート後に新機能を紹介する「What's New」画面を、少ないコードで実装するための SwiftUI 製 Swift Package です。

- バージョンをまたいだページ送り（TabView + ページングスタイル）
- ページ単位のON/OFFトグル（機能フラグの初回案内などに）
- 既読バージョンの永続化（デフォルトは UserDefaults、任意のストレージに差し替え可能）
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

### 2. 未読ページを判定する

`OCWhatsNew` が、バージョン文字列を数値として比較して未読ページを絞り込みます。

```swift
import OCWhatsNew

let store = OCUserDefaultsWhatsNewVersionStore()
let unseenItems = OCWhatsNew.unseenItems(
    in: MyAppWhatsNewCatalog.allItems,
    lastSeenVersion: store.lastSeenVersion
)

if !unseenItems.isEmpty {
    // showWhatsNew = true など、シート表示のトリガーにする
}
```

新規ユーザーには過去のお知らせを見せず最新版を既読扱いにしたい、といったアプリ固有の分岐は
`OCWhatsNew.latestVersion(in:)` を使って呼び出し側で組み立ててください。

```swift
if isNewUser {
    store.lastSeenVersion = OCWhatsNew.latestVersion(in: MyAppWhatsNewCatalog.allItems)
}
```

### 3. シートとして表示する

```swift
import OCWhatsNew

struct HomeView: View {
    @State private var showWhatsNew = false
    @State private var whatsNewItems: [OCWhatsNewItem] = []

    var body: some View {
        Text("Home")
            .sheet(isPresented: $showWhatsNew) {
                OCWhatsNewView(items: whatsNewItems, isPresented: $showWhatsNew)
            }
    }
}
```

`OCWhatsNewView` はシート確定時（最終ページで「はじめる」をタップしたタイミング）に

1. 各ページのトグルに設定された `set` クロージャを呼んで選択内容を保存し、
2. `store.lastSeenVersion` に `items` 内の最新バージョンを書き込みます。

これにより、次回起動時は同じお知らせが再表示されません。

## カスタマイズ

### 見た目 (`OCWhatsNewStyle`)

```swift
OCWhatsNewView(
    items: unseenItems,
    isPresented: $showWhatsNew,
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

### 文言 (`OCWhatsNewTexts`)

```swift
OCWhatsNewView(
    items: unseenItems,
    isPresented: $showWhatsNew,
    texts: OCWhatsNewTexts(
        title: "whats_new_title",
        subtitle: "whats_new_subtitle",
        nextButton: "whats_new_next",
        startButton: "whats_new_start"
    )
)
```

`LocalizedStringKey` を受け取るため、アプリの `Localizable.strings` のキーをそのまま渡せます。

### 既読バージョンの保存先 (`OCWhatsNewVersionStoring`)

既定では `OCUserDefaultsWhatsNewVersionStore`（`UserDefaults.standard` に保存）を使いますが、
既に自前の永続化層を持っている場合はプロトコルに準拠させて差し替えられます。

```swift
final class AppDefaultsWhatsNewVersionStore: OCWhatsNewVersionStoring {
    var lastSeenVersion: String? {
        get { AppDefaults.lastSeenWhatsNewVersion }
        set { AppDefaults.lastSeenWhatsNewVersion = newValue }
    }
}

OCWhatsNewView(items: unseenItems, isPresented: $showWhatsNew, store: AppDefaultsWhatsNewVersionStore())
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
