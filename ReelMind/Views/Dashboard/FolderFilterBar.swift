import SwiftUI

public struct FolderFilterBar: View {
    public let folders: [Folder]
    @Binding public var selectedFolderId: String?

    public init(folders: [Folder], selectedFolderId: Binding<String?>) {
        self.folders = folders
        self._selectedFolderId = selectedFolderId
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedFolderId = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.fill")
                        Text("All")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedFolderId == nil ? Color.accentColor : Color(.secondarySystemFill))
                    .foregroundStyle(selectedFolderId == nil ? .white : .primary)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Show all folders")

                ForEach(folders) { folder in
                    Button {
                        selectedFolderId = folder.id
                    } label: {
                        HStack(spacing: 6) {
                            Text(folder.icon)
                            Text(folder.name)
                            if folder.totalReelCount > 0 {
                                Text("\(folder.totalReelCount)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(selectedFolderId == folder.id ? Color.white.opacity(0.25) : Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedFolderId == folder.id ? Color.accentColor : Color(.secondarySystemFill))
                        .foregroundStyle(selectedFolderId == folder.id ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Filter by folder \(folder.name)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}
