import Foundation
import Testing
@testable import OCWhatsNew

// MARK: - OCWhatsNew (バージョン比較)

@Suite("OCWhatsNew")
struct OCWhatsNewTests {
    private func makeItem(_ version: String) -> OCWhatsNewItem {
        OCWhatsNewItem(version: version, iconSystemName: "star", title: "title", detail: "detail")
    }

    @Test("latestVersion はカタログ内で最大のバージョンを返す")
    func latestVersionReturnsMax() {
        let items = ["1.0.0", "2.10.0", "2.9.0"].map(makeItem)
        #expect(OCWhatsNew.latestVersion(in: items) == "2.10.0")
    }

    @Test("latestVersion は空配列に対して nil を返す")
    func latestVersionEmpty() {
        #expect(OCWhatsNew.latestVersion(in: []) == nil)
    }

    @Test("unseenItems は lastSeenVersion が nil のとき全件を返す")
    func unseenItemsWhenNoLastSeenVersion() {
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: nil)
        #expect(unseen.count == 2)
    }

    @Test("unseenItems は lastSeenVersion より新しいものだけをバージョン昇順で返す")
    func unseenItemsFiltersAndSorts() {
        let items = ["1.0.0", "2.10.0", "2.9.0", "1.5.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: "1.5.0")
        #expect(unseen.map(\.version) == ["2.9.0", "2.10.0"])
    }

    @Test("unseenItems は数値としてバージョンを比較する（文字列比較では壊れるケース）")
    func unseenItemsComparesNumerically() {
        let items = ["1.9.0", "1.10.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: "1.9.0")
        #expect(unseen.map(\.version) == ["1.10.0"])
    }

    @Test("unseenItems は同一バージョンを未読に含めない")
    func unseenItemsExcludesSameVersion() {
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: "1.1.0")
        #expect(unseen.isEmpty)
    }

    @Test("unseenItems は初回起動でも showOnFirstLaunch が true なら全件を返す")
    func unseenItemsShowsOnFirstLaunchWhenEnabled() {
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: nil, showOnFirstLaunch: true)
        #expect(unseen.count == 2)
    }

    @Test("unseenItems は初回起動かつ showOnFirstLaunch が false なら空を返す")
    func unseenItemsHidesOnFirstLaunchWhenDisabled() {
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let unseen = OCWhatsNew.unseenItems(in: items, lastSeenVersion: nil, showOnFirstLaunch: false)
        #expect(unseen.isEmpty)
    }
}

// MARK: - OCWhatsNew.itemsToPresent

@Suite("OCWhatsNew.itemsToPresent")
struct OCWhatsNewItemsToPresentTests {
    private func makeItem(_ version: String) -> OCWhatsNewItem {
        OCWhatsNewItem(version: version, iconSystemName: "star", title: "title", detail: "detail")
    }

    private func makeStore(suiteName: String) -> OCUserDefaultsWhatsNewVersionStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return OCUserDefaultsWhatsNewVersionStore(userDefaults: defaults, key: "test.lastSeenVersion")
    }

    @Test("初回起動かつ showOnFirstLaunch が false のとき、空を返し最新を既読として記録する")
    func firstLaunchHiddenBaselinesStore() {
        let store = makeStore(suiteName: "OCWhatsNewTests.itemsToPresent.firstHidden")
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let toPresent = OCWhatsNew.itemsToPresent(in: items, store: store, showOnFirstLaunch: false)
        #expect(toPresent.isEmpty)
        #expect(store.lastSeenVersion == "1.1.0")
    }

    @Test("初回起動で既読を記録したあと、アップデートで追加された新機能だけが表示される")
    func afterBaselineOnlyNewItemsAppear() {
        let store = makeStore(suiteName: "OCWhatsNewTests.itemsToPresent.afterBaseline")
        // 初回起動: 1.1.0 までのカタログを静かに既読化
        _ = OCWhatsNew.itemsToPresent(in: ["1.0.0", "1.1.0"].map(makeItem), store: store, showOnFirstLaunch: false)
        // アップデート後: 2.0.0 が追加された
        let toPresent = OCWhatsNew.itemsToPresent(in: ["1.0.0", "1.1.0", "2.0.0"].map(makeItem), store: store, showOnFirstLaunch: false)
        #expect(toPresent.map(\.version) == ["2.0.0"])
    }

    @Test("初回起動でも showOnFirstLaunch が true なら全件を表示する")
    func firstLaunchShownReturnsAll() {
        let store = makeStore(suiteName: "OCWhatsNewTests.itemsToPresent.firstShown")
        let items = ["1.0.0", "1.1.0"].map(makeItem)
        let toPresent = OCWhatsNew.itemsToPresent(in: items, store: store, showOnFirstLaunch: true)
        #expect(toPresent.count == 2)
        // 表示する場合はここでは既読化しない（確定は OCWhatsNewViewModel.commit が担う）
        #expect(store.lastSeenVersion == nil)
    }
}

// MARK: - OCUserDefaultsWhatsNewVersionStore

@Suite("OCUserDefaultsWhatsNewVersionStore")
struct UserDefaultsWhatsNewVersionStoreTests {
    private func makeStore(suiteName: String) -> OCUserDefaultsWhatsNewVersionStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return OCUserDefaultsWhatsNewVersionStore(userDefaults: defaults, key: "test.lastSeenVersion")
    }

    @Test("初期状態では lastSeenVersion は nil")
    func initiallyNil() {
        let store = makeStore(suiteName: "OCWhatsNewTests.initiallyNil")
        #expect(store.lastSeenVersion == nil)
    }

    @Test("設定した値が読み出せる")
    func setAndGet() {
        let store = makeStore(suiteName: "OCWhatsNewTests.setAndGet")
        store.lastSeenVersion = "1.2.3"
        #expect(store.lastSeenVersion == "1.2.3")
    }

    @Test("nil を設定すると値がクリアされる")
    func setNilClearsValue() {
        let store = makeStore(suiteName: "OCWhatsNewTests.setNilClearsValue")
        store.lastSeenVersion = "1.2.3"
        store.lastSeenVersion = nil
        #expect(store.lastSeenVersion == nil)
    }
}

// MARK: - OCWhatsNewViewModel
// OCWhatsNewViewModel は OCWhatsNewView (ページ送り TabView) 専用の内部型で、
// この UI は AppKit (macOS) をサポートしないため、対応プラットフォームでのみテストする

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

/// テスト専用。`@Sendable` クロージャ越しに書き込み結果を保持するための箱
private final class ResultBox<Value>: @unchecked Sendable {
    var value: Value?
}

@MainActor
@Suite("OCWhatsNewViewModel")
struct OCWhatsNewViewModelTests {
    private func makeItem(version: String, toggle: OCWhatsNewToggle? = nil) -> OCWhatsNewItem {
        OCWhatsNewItem(version: version, iconSystemName: "star", title: "title", detail: "detail", toggle: toggle)
    }

    @Test("isLastPage は最後のページで true になる")
    func isLastPage() {
        let items = ["1.0.0", "1.1.0"].map { makeItem(version: $0) }
        let viewModel = OCWhatsNewViewModel(items: items)
        #expect(viewModel.isLastPage == false)
        viewModel.advance()
        #expect(viewModel.isLastPage == true)
    }

    @Test("advance は最終ページを超えて進まない")
    func advanceStopsAtLastPage() {
        let items = ["1.0.0"].map { makeItem(version: $0) }
        let viewModel = OCWhatsNewViewModel(items: items)
        viewModel.advance()
        #expect(viewModel.currentIndex == 0)
    }

    @Test("初期化時に各トグルの現在値を取得する")
    func initializesToggleStatesFromGetter() {
        let toggle = OCWhatsNewToggle(title: "toggle", get: { true }, set: { _ in })
        let item = makeItem(version: "1.0.0", toggle: toggle)
        let viewModel = OCWhatsNewViewModel(items: [item])
        #expect(viewModel.toggleBinding(for: item.id).wrappedValue == true)
    }

    @Test("commit はトグルの値を保存し、最新バージョンを既読にする")
    func commitPersistsToggleAndVersion() {
        let savedToggleValue = ResultBox<Bool>()
        let toggle = OCWhatsNewToggle(title: "toggle", get: { false }, set: { savedToggleValue.value = $0 })
        let item = makeItem(version: "1.2.0", toggle: toggle)
        let viewModel = OCWhatsNewViewModel(items: [item])
        viewModel.toggleBinding(for: item.id).wrappedValue = true

        let store = OCUserDefaultsWhatsNewVersionStore(
            userDefaults: UserDefaults(suiteName: "OCWhatsNewTests.commit")!,
            key: "test.commit.lastSeenVersion"
        )
        viewModel.commit(store: store)

        #expect(savedToggleValue.value == true)
        #expect(store.lastSeenVersion == "1.2.0")
    }
}

#endif
