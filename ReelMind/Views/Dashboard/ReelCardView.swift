import SwiftUI

public struct ReelCardView: View {
    public let reel: Reel
    public let onToggleFavorite: () -> Void

    public init(reel: Reel, onToggleFavorite: @escaping () -> Void) {
        self.reel = reel
        self.onToggleFavorite = onToggleFavorite
    }

    private var platformBadgeColor: Color {
        switch reel.platform.lowercased() {
        case "instagram": return .purple
        case "tiktok": return .black
        case "youtube": return .red
        case "x", "twitter": return .blue
        default: return .gray
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Platform & Favorite Toggle
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(platformBadgeColor)
                        .frame(width: 8, height: 8)
                    Text(reel.platform.capitalized)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let time = reel.estimatedTime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                        Text(time)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Button(action: onToggleFavorite) {
                    Image(systemName: reel.status == "favorite" ? "heart.fill" : "heart")
                        .foregroundStyle(reel.status == "favorite" ? .red : .secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(reel.status == "favorite" ? "Remove from favorites" : "Add to favorites")
            }

            // Title
            Text(reel.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            // Executive Summary
            Text(reel.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // AI Tools Pills
            if !reel.aiTools.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(reel.aiTools, id: \.self) { tool in
                            Text(tool)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(.rect(cornerRadius: 6))
                        }
                    }
                }
            }

            // Footer info
            HStack {
                if !reel.prompts.isEmpty {
                    Label("\(reel.prompts.count) Prompts", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !reel.keySteps.isEmpty {
                    Label("\(reel.keySteps.count) Steps", systemImage: "list.number")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(reel.difficulty)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
