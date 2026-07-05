//
//  WhatsNewView.swift
//  OCWhatsNew
//

// ページ送り TabView (.page スタイル) は AppKit (macOS) には存在しないため、
// 対応プラットフォームのみでビルドする
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

import SwiftUI

/// アプリ起動時などに新機能を紹介するためのシート型View。
///
/// 使い方の例:
/// ```swift
/// .sheet(isPresented: $showWhatsNew) {
///     WhatsNewView(items: unseenItems, isPresented: $showWhatsNew)
/// }
/// ```
///
/// `items` に渡すページごとにトグル（機能のON/OFF）を設定でき、シート確定時に
/// `WhatsNewToggle.set` が呼ばれる。また確定と同時に `store`（既定は
/// `UserDefaultsWhatsNewVersionStore`）へ `items` 内の最新バージョンが既読として保存される
public struct WhatsNewView: View {
    @StateObject private var viewModel: WhatsNewViewModel
    @Binding var isPresented: Bool
    private let store: WhatsNewVersionStoring
    private let texts: WhatsNewTexts
    private let style: WhatsNewStyle

    public init(
        items: [WhatsNewItem],
        isPresented: Binding<Bool>,
        store: WhatsNewVersionStoring = UserDefaultsWhatsNewVersionStore(),
        texts: WhatsNewTexts = WhatsNewTexts(),
        style: WhatsNewStyle = WhatsNewStyle()
    ) {
        _viewModel = StateObject(wrappedValue: WhatsNewViewModel(items: items))
        _isPresented = isPresented
        self.store = store
        self.texts = texts
        self.style = style
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(style.background)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleView
                    .padding(.top, 40)
                    .padding(.bottom, 12)

                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: viewModel.items.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled()
    }

    private var titleView: some View {
        VStack(spacing: 8) {
            Text(texts.title)
                .font(style.titleFont)
                .foregroundStyle(style.foregroundColor)

            if let subtitle = texts.subtitle {
                Text(subtitle)
                    .font(style.subtitleFont)
                    .foregroundStyle(style.secondaryForegroundColor)
            }
        }
    }

    private func pageView(_ item: WhatsNewItem) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: item.iconSystemName)
                    .font(.system(size: 56))
                    .foregroundStyle(style.foregroundColor)
                    .padding(.top, 8)

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
                    .toggleStyle(WhatsNewToggleStyle(accentColor: style.accentColor, thumbColor: style.foregroundColor))
                    .padding(16)
                    .background(style.foregroundColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style.foregroundColor.opacity(0.25), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var bottomButton: some View {
        Button {
            if viewModel.isLastPage {
                viewModel.commit(store: store)
                isPresented = false
            } else {
                withAnimation { viewModel.advance() }
            }
        } label: {
            Text(viewModel.isLastPage ? texts.startButton : texts.nextButton)
                .font(style.headlineFont)
                .foregroundStyle(style.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(style.foregroundColor, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct WhatsNewToggleStyle: ToggleStyle {
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
private final class WhatsNewPreviewToggleBox: @unchecked Sendable {
    var isEnabled = true
}

private struct WhatsNewView_Preview: View {
    @State private var isPresented = true
    private let toggleBox = WhatsNewPreviewToggleBox()

    var body: some View {
        WhatsNewView(
            items: [
                WhatsNewItem(
                    version: "1.1.0",
                    iconSystemName: "flag.checkered",
                    title: "New Feature",
                    detail: "Describe the new feature here.",
                    note: "Optional supplementary note.",
                    toggle: WhatsNewToggle(
                        title: "Enable this feature",
                        get: { [toggleBox] in toggleBox.isEnabled },
                        set: { [toggleBox] in toggleBox.isEnabled = $0 }
                    )
                )
            ],
            isPresented: $isPresented
        )
    }
}

#Preview {
    WhatsNewView_Preview()
}
#endif

#endif
