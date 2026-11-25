import Foundation

public struct Organization: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slug: String
    public let description: String
    public let ownerId: String
    public let ownerUsername: String?
    public let role: String?
    public let membersCount: Int
    public let reelsCount: Int
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, role
        case ownerId = "owner_id"
        case ownerUsername = "owner_username"
        case membersCount = "members_count"
        case reelsCount = "reels_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String,
        name: String,
        slug: String,
        description: String = "",
        ownerId: String = "",
        ownerUsername: String? = nil,
        role: String? = nil,
        membersCount: Int = 1,
        reelsCount: Int = 0,
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.description = description
        self.ownerId = ownerId
        self.ownerUsername = ownerUsername
        self.role = role
        self.membersCount = membersCount
        self.reelsCount = reelsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct OrganizationMember: Codable, Identifiable, Hashable, Sendable {
    public var id: String { userId }
    public let userId: String
    public let username: String
    public let role: String
    public let joinedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username, role
        case joinedAt = "joined_at"
    }

    public init(userId: String, username: String, role: String = "member", joinedAt: String = "") {
        self.userId = userId
        self.username = username
        self.role = role
        self.joinedAt = joinedAt
    }
}

public struct OrganizationDetail: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let slug: String
    public let description: String
    public let ownerId: String
    public let ownerUsername: String?
    public let role: String?
    public let membersCount: Int
    public let reelsCount: Int
    public let members: [OrganizationMember]
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, role, members
        case ownerId = "owner_id"
        case ownerUsername = "owner_username"
        case membersCount = "members_count"
        case reelsCount = "reels_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
