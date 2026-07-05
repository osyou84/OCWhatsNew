//
//  WhatsNewStyle.swift
//  OCWhatsNew
//

import SwiftUI

/// `WhatsNewView` の見た目をアプリ側からカスタマイズするためのスタイル定義。
/// 指定しない場合は SwiftUI 標準の Accent Color を使ったデフォルト外観になる
public struct WhatsNewStyle {
    public var background: AnyShapeStyle
    public var foregroundColor: Color
    public var secondaryForegroundColor: Color
    public var accentColor: Color
    public var titleFont: Font
    public var subtitleFont: Font
    public var headlineFont: Font
    public var bodyFont: Font
    public var captionFont: Font

    public init(
        background: AnyShapeStyle = AnyShapeStyle(LinearGradient(
            colors: [.accentColor, .accentColor.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )),
        foregroundColor: Color = .white,
        secondaryForegroundColor: Color = .white.opacity(0.85),
        accentColor: Color = .accentColor,
        titleFont: Font = .title.bold(),
        subtitleFont: Font = .subheadline,
        headlineFont: Font = .title3.bold(),
        bodyFont: Font = .body,
        captionFont: Font = .caption
    ) {
        self.background = background
        self.foregroundColor = foregroundColor
        self.secondaryForegroundColor = secondaryForegroundColor
        self.accentColor = accentColor
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.headlineFont = headlineFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
    }
}

/// `WhatsNewView` に表示する文言。アプリ側の `Localizable.strings` のキーをそのまま渡せる
public struct WhatsNewTexts {
    public var title: LocalizedStringKey
    public var subtitle: LocalizedStringKey?
    public var nextButton: LocalizedStringKey
    public var startButton: LocalizedStringKey

    public init(
        title: LocalizedStringKey = "What's New",
        subtitle: LocalizedStringKey? = nil,
        nextButton: LocalizedStringKey = "Next",
        startButton: LocalizedStringKey = "Continue"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.nextButton = nextButton
        self.startButton = startButton
    }
}
