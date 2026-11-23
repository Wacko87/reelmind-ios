import Foundation

public struct Reel: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let url: String
    public let platform: String
    public let author: String?
    public let authorUrl: String?
    public let originalTitle: String?
    public let thumbnailUrl: String?
    public let duration: Double?
    public var title: String
    public var summary: String
    public var aiTools: [String]
    public var keySteps: [String]
    public var prompts: [String]
    public var tags: [String]
    public var difficulty: String
    public var estimatedTime: String?
    public var status: String
    public var userNotes: String
    public var folderId: String?
    public var folderName: String?
    public var mediaType: String
    public var images: [String]
    public let isDuplicate: Bool?
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case platform
        case author
        case authorUrl = "author_url"
        case originalTitle = "original_title"
        case thumbnailUrl = "thumbnail_url"
        case duration
        case title
        case summary
        case aiTools = "ai_tools"
        case keySteps = "key_steps"
        case prompts
        case tags
        case difficulty
        case estimatedTime = "estimated_time"
        case status
        case userNotes = "user_notes"
        case folderId = "folder_id"
        case folderName = "folder_name"
        case mediaType = "media_type"
        case images
        case isDuplicate = "is_duplicate"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String = UUID().uuidString,
        url: String,
        platform: String,
        author: String? = nil,
        authorUrl: String? = nil,
        originalTitle: String? = nil,
        thumbnailUrl: String? = nil,
        duration: Double? = nil,
        title: String,
        summary: String,
        aiTools: [String] = [],
        keySteps: [String] = [],
        prompts: [String] = [],
        tags: [String] = [],
        difficulty: String = "Intermedio",
        estimatedTime: String? = "15-30 min",
        status: String = "pending",
        userNotes: String = "",
        folderId: String? = nil,
        folderName: String? = nil,
        mediaType: String = "reel",
        images: [String] = [],
        isDuplicate: Bool? = false,
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.id = id
        self.url = url
        self.platform = platform
        self.author = author
        self.authorUrl = authorUrl
        self.originalTitle = originalTitle
        self.thumbnailUrl = thumbnailUrl
        self.duration = duration
        self.title = title
        self.summary = summary
        self.aiTools = aiTools
        self.keySteps = keySteps
        self.prompts = prompts
        self.tags = tags
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.status = status
        self.userNotes = userNotes
        self.folderId = folderId
        self.folderName = folderName
        self.mediaType = mediaType
        self.images = images
        self.isDuplicate = isDuplicate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ReelAnalyzeRequest: Codable, Sendable {
    public let url: String
    public let folderId: String?
    public let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case url
        case folderId = "folder_id"
        case mediaType = "media_type"
    }

    public init(url: String, folderId: String? = nil, mediaType: String? = "auto") {
        self.url = url
        self.folderId = folderId
        self.mediaType = mediaType
    }
}

public struct ReelUpdateRequest: Codable, Sendable {
    public let status: String?
    public let userNotes: String?
    public let title: String?
    public let tags: [String]?
    public let folderId: String?
    public let mediaType: String?
    public let estimatedTime: String?

    enum CodingKeys: String, CodingKey {
        case status
        case userNotes = "user_notes"
        case title
        case tags
        case folderId = "folder_id"
        case mediaType = "media_type"
        case estimatedTime = "estimated_time"
    }

    public init(
        status: String? = nil,
        userNotes: String? = nil,
        title: String? = nil,
        tags: [String]? = nil,
        folderId: String? = nil,
        mediaType: String? = nil,
        estimatedTime: String? = nil
    ) {
        self.status = status
        self.userNotes = userNotes
        self.title = title
        self.tags = tags
        self.folderId = folderId
        self.mediaType = mediaType
        self.estimatedTime = estimatedTime
    }
}
