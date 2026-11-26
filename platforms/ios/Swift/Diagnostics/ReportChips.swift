// ReportChips.swift — wrapping chip rows for the report sheet
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct ChipFlow<Content: View>: View {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 6, lineSpacing: CGFloat = 6, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            content()
        }
    }
}
