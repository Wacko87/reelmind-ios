import Foundation

public struct Folder: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public var name: String
    public var parentId: String?
    public var icon: String
    public var color: String
    public var reelCount: Int
    public var totalReelCount: Int
    public var orgId: String?
    public var children: [Folder]
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case parentId = "parent_id"
        case icon
        case color
        case reelCount = "reel_count"
        case totalReelCount = "total_reel_count"
        case orgId = "org_id"
        case children
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        parentId: String? = nil,
        icon: String = "📁",
        color: String = "#8b5cf6",
        reelCount: Int = 0,
        totalReelCount: Int = 0,
        orgId: String? = nil,
        children: [Folder] = [],
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.icon = icon
        self.color = color
        self.reelCount = reelCount
        self.totalReelCount = totalReelCount
        self.orgId = orgId
        self.children = children
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct FolderCreateRequest: Codable, Sendable {
    public let name: String
    public let parentId: String?
    public let icon: String
    public let color: String
    public let orgId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case parentId = "parent_id"
        case icon
        case color
        case orgId = "org_id"
    }

    public init(name: String, parentId: String? = nil, icon: String = "📁", color: String = "#8b5cf6", orgId: String? = nil) {
        self.name = name
        self.parentId = parentId
        self.icon = icon
        self.color = color
        self.orgId = orgId
    }
}
