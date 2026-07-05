//
//  OCWhatsNewStyle.swift
//  OCWhatsNew
//

import SwiftUI

/// `whatsNewSheet` の見た目をアプリ側からカスタマイズするためのスタイル定義。
/// 指定しない場合は SwiftUI 標準の Accent Color を使ったデフォルト外観になる
public struct OCWhatsNewStyle {
    public var background: AnyShapeStyle
    public var foregroundColor: Color
    public var secondaryForegroundColor: Color
    public var accentColor: Color
    public var titleFont: Font
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
        headlineFont: Font = .title3.bold(),
        bodyFont: Font = .body,
        captionFont: Font = .caption
    ) {
        self.background = background
        self.foregroundColor = foregroundColor
        self.secondaryForegroundColor = secondaryForegroundColor
        self.accentColor = accentColor
        self.titleFont = titleFont
        self.headlineFont = headlineFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
    }
}
