//
//  OCWhatsNewView.swift
//  OCWhatsNew
//

// ページ送り TabView (.page スタイル) は AppKit (macOS) には存在しないため、
// 対応プラットフォームのみでビルドする
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

import SwiftUI

// MARK: - whatsNewSheet モディファイア

public extension View {
    /// 未読の What's New があれば、この View の表示時に自動でシート表示する。
    ///
    /// 事前に `OCWhatsNew.configure(items:)` でカタログを登録しておくこと。
    /// 表示判定・初回起動の既読化・確定時の既読記録はすべてライブラリ側が処理する。
    ///
    /// ```swift
    /// MainView()
    ///     .whatsNewSheet(
    ///         title: "WhatsNew Title",
    ///         nextButton: "WhatsNew Next",
    ///         startButton: "WhatsNew Start"
    ///     )
    /// ```
    func whatsNewSheet(
        title: LocalizedStringKey = "What's New",
        nextButton: LocalizedStringKey = "Next",
        startButton: LocalizedStringKey = "Continue",
        style: OCWhatsNewStyle = OCWhatsNewStyle()
    ) -> some View {
        modifier(OCWhatsNewSheetModifier(
            title: title,
            nextButton: nextButton,
            startButton: startButton,
            style: style
        ))
    }
}

/// `.sheet(item:)` でデータとともに原子的に提示するためのラッパー。
/// isPresented ＋別 State だと提示時に空配列を読み取ることがあるため item 方式にする
private struct OCWhatsNewPresentation: Identifiable {
    let id = UUID()
    let items: [OCWhatsNewItem]
}

private struct OCWhatsNewSheetModifier: ViewModifier {
    let title: LocalizedStringKey
    let nextButton: LocalizedStringKey
    let startButton: LocalizedStringKey
    let style: OCWhatsNewStyle

    @State private var presentation: OCWhatsNewPresentation?
    @State private var didCheck = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                // onAppear は再表示などで複数回呼ばれうるため、判定は一度だけ行う
                guard !didCheck else { return }
                didCheck = true
                let items = OCWhatsNew.takeItemsToPresent()
                guard !items.isEmpty else { return }
                presentation = OCWhatsNewPresentation(items: items)
            }
            .sheet(item: $presentation) { presentation in
                OCWhatsNewView(
                    items: presentation.items,
                    title: title,
                    nextButton: nextButton,
                    startButton: startButton,
                    style: style,
                    dismiss: { self.presentation = nil }
                )
            }
    }
}

// MARK: - OCWhatsNewView

/// 新機能を紹介するシート本体。`whatsNewSheet` モディファイア経由でのみ生成される。
/// 各ページのトグル選択と既読バージョンは、最終ページのボタン確定時に保存される
struct OCWhatsNewView: View {
    @StateObject private var viewModel = OCWhatsNewViewModel()
    let items: [OCWhatsNewItem]
    let title: LocalizedStringKey
    let nextButton: LocalizedStringKey
    let startButton: LocalizedStringKey
    let style: OCWhatsNewStyle
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            titleView
                .padding(.vertical, 20)

            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    pageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: items.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))

            bottomButton
                .padding(.horizontal, 16)
                .frame(maxWidth: 600)
        }
        .padding(.vertical, 16)
        .background(style.background)
        .interactiveDismissDisabled()
        .onAppear { viewModel.prepare(items: items) }
    }

    private var titleView: some View {
        Text(title)
            .font(style.titleFont)
            .foregroundStyle(style.foregroundColor)
    }

    private func pageView(_ item: OCWhatsNewItem) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: item.iconSystemName)
                    .font(.system(size: 56))
                    .foregroundStyle(style.foregroundColor)

                Text(LocalizedStringKey(item.title))
                    .font(style.headlineFont)
                    .foregroundStyle(style.foregroundColor)
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey(item.detail))
                    .font(style.bodyFont)
                    .foregroundStyle(style.secondaryForegroundColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let note = item.note {
                    Text(LocalizedStringKey(note))
                        .font(style.captionFont)
                        .foregroundStyle(style.secondaryForegroundColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let toggle = item.toggle {
                    Toggle(isOn: viewModel.toggleBinding(for: item.id)) {
                        Text(LocalizedStringKey(toggle.title))
                            .font(style.bodyFont)
                            .foregroundStyle(style.foregroundColor)
                    }
                    .toggleStyle(OCWhatsNewToggleStyle(accentColor: style.accentColor, thumbColor: style.foregroundColor))
                    .padding(16)
                    .background(style.foregroundColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style.foregroundColor.opacity(0.25), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: 600)
            .padding(.top, 40)
        }
    }

    private var bottomButton: some View {
        Button {
            if viewModel.isLastPage(pageCount: items.count) {
                viewModel.commit(items: items, store: OCWhatsNew.store)
                dismiss()
            } else {
                withAnimation { viewModel.advance(pageCount: items.count) }
            }
        } label: {
            Text(viewModel.isLastPage(pageCount: items.count) ? startButton : nextButton)
                .font(style.headlineFont)
                .foregroundStyle(style.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(style.foregroundColor, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct OCWhatsNewToggleStyle: ToggleStyle {
    let accentColor: Color
    let thumbColor: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? accentColor : thumbColor.opacity(0.25))
                    .frame(width: 48, height: 28)
                    .overlay(Capsule().stroke(thumbColor.opacity(0.5), lineWidth: 1))

                Circle()
                    .fill(thumbColor)
                    .frame(width: 22, height: 22)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            }
            .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

#if DEBUG
/// プレビュー専用。トグルの状態を `@Sendable` クロージャ越しに保持するための箱
private final class OCWhatsNewPreviewToggleBox: @unchecked Sendable {
    var isEnabled = true
}

#Preview {
    let toggleBox = OCWhatsNewPreviewToggleBox()
    return Text("")
        .sheet(isPresented: .constant(true)) {
            OCWhatsNewView(
                items: [
                    OCWhatsNewItem(
                        version: "1.1.0",
                        iconSystemName: "flag.checkered",
                        title: "New Feature",
                        detail: "Describe the new feature here.",
                        note: "Optional supplementary note.",
                        toggle: OCWhatsNewToggle(
                            title: "Enable this feature",
                            get: { [toggleBox] in toggleBox.isEnabled },
                            set: { [toggleBox] in toggleBox.isEnabled = $0 }
                        )
                    ),
                    OCWhatsNewItem(
                        version: "1.1.0",
                        iconSystemName: "flag.checkered",
                        title: "New Feature",
                        detail: "Describe the new feature here.",
                        note: "Optional supplementary note.",
                        toggle: OCWhatsNewToggle(
                            title: "Enable this feature",
                            get: { [toggleBox] in toggleBox.isEnabled },
                            set: { [toggleBox] in toggleBox.isEnabled = $0 }
                        )
                    )
                ],
                title: "What's New",
                nextButton: "Next",
                startButton: "Continue",
                style: OCWhatsNewStyle(),
                dismiss: {}
            )
        }
}
#endif

#endif
