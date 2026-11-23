import SwiftUI

public struct StepsSectionView: View {
    public let steps: [String]

    public init(steps: [String]) {
        self.steps = steps
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Step-by-Step Blueprint", systemImage: "list.number")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Circle())

                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
