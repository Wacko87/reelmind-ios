import SwiftUI

public struct PromptsSectionView: View {
    public let prompts: [String]
    public let onCopy: (String) -> Void

    public init(prompts: [String], onCopy: @escaping (String) -> Void) {
        self.prompts = prompts
        self.onCopy = onCopy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Extracted Prompts & Formulas", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prompt #\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            onCopy(prompt)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel("Copy prompt number \(index + 1)")
                    }

                    Text(prompt)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 10))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
