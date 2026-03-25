import Foundation

public struct FyydPodcastListWithPaging: Sendable {
    public let podcasts: [FyydPodcast]
    public let paging: PagingInfo?

    public init(podcasts: [FyydPodcast], paging: PagingInfo?) {
        self.podcasts = podcasts
        self.paging = paging
    }
}

public struct FyydCollectionListWithPaging: Sendable {
    public let collections: [FyydCollection]
    public let paging: PagingInfo?

    public init(collections: [FyydCollection], paging: PagingInfo?) {
        self.collections = collections
        self.paging = paging
    }
}

public struct FyydCurationListWithPaging: Sendable {
    public let curations: [FyydCuration]
    public let paging: PagingInfo?

    public init(curations: [FyydCuration], paging: PagingInfo?) {
        self.curations = curations
        self.paging = paging
    }
}

public struct FyydPodcastDetails: Sendable {
    public let podcast: FyydPodcast
    public let paging: PagingInfo?

    public init(podcast: FyydPodcast, paging: PagingInfo?) {
        self.podcast = podcast
        self.paging = paging
    }
}

public struct FyydCategoryPodcastsPage: Sendable {
    public let category: FyydCategorySummary?
    public let parent: FyydCategorySummary?
    public let podcasts: [FyydPodcast]
    public let paging: PagingInfo?

    public init(category: FyydCategorySummary?, parent: FyydCategorySummary?, podcasts: [FyydPodcast], paging: PagingInfo?) {
        self.category = category
        self.parent = parent
        self.podcasts = podcasts
        self.paging = paging
    }
}

public struct FyydCategoryCurationsPage: Sendable {
    public let category: FyydCategorySummary?
    public let parent: FyydCategorySummary?
    public let curations: [FyydCuration]
    public let paging: PagingInfo?

    public init(category: FyydCategorySummary?, parent: FyydCategorySummary?, curations: [FyydCuration], paging: PagingInfo?) {
        self.category = category
        self.parent = parent
        self.curations = curations
        self.paging = paging
    }
}

public struct FyydUploadImage: Sendable {
    public let data: Data
    public let filename: String
    public let mimeType: String

    public init(data: Data, filename: String = "image.jpg", mimeType: String = "image/jpeg") {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

public struct FyydUser: Decodable, Sendable, Equatable {
    public let nick: String?
    public let id: Int
    public let fullname: String?
    public let bio: String?
    public let url: String?
    public let layoutImageURL: String?
    public let thumbImageURL: String?
    public let smallImageURL: String?
    public let microImageURL: String?
}

public struct FyydAction: Decodable, Sendable, Equatable {
    public let id: Int
    public let objectId: Int
    public let objectType: String
    public let action: String
    public let metadata: String?
    public let date: String?
    public let userId: Int?
    public let appId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case objectId = "object_id"
        case objectType = "object_type"
        case action
        case metadata
        case date
        case userId = "user_id"
        case appId = "app_id"
    }
}

public struct FyydCategorySummary: Decodable, Sendable, Equatable {
    public let id: Int
    public let slug: String?
    public let title: String?
    public let url: String?
}

public struct PagingInfo: Decodable, Sendable, Equatable {
    public let count: Int?
    public let page: Int?
    public let firstPage: Int?
    public let lastPage: Int?
    public let nextPage: Int?
    public let prevPage: Int?

    enum CodingKeys: String, CodingKey {
        case count
        case page
        case firstPage = "first_page"
        case lastPage = "last_page"
        case nextPage = "next_page"
        case prevPage = "prev_page"
    }
}

public struct FyydStats: Decodable, Sendable, Equatable {
    public let medianDuration: Int?
    public let medianDurationString: String?
    public let episodeCount: Int?
    public let publishInterval: Int?
    public let publishIntervalString: String?
    public let publishIntervalValue: Int?
    public let publishIntervalType: Int?

    enum CodingKeys: String, CodingKey {
        case medianDuration = "medianduration"
        case medianDurationString = "medianduration_string"
        case episodeCount = "episodecount"
        case publishInterval = "pubinterval"
        case publishIntervalString = "pubinterval_string"
        case publishIntervalValue = "pubinterval_value"
        case publishIntervalType = "pubinterval_type"
    }
}

public struct FyydChapter: Decodable, Sendable, Equatable {
    public let start: String?
    public let startMs: Int?
    public let title: String?

    enum CodingKeys: String, CodingKey {
        case start
        case startMs = "start_ms"
        case title
    }
}

public struct FyydPodcast: Decodable, Sendable, Equatable {
    public let id: Int
    public let title: String?
    public let subtitle: String
    public let author: String?
    public let lastpub: String
    public let description: String?
    public let imgURL: String?
    public let xmlURL: String?
    public let htmlURL: String?
    public let status: Int?
    public let slug: String?
    public let layoutImageURL: String?
    public let thumbImageURL: String?
    public let smallImageURL: String?
    public let microImageURL: String?
    public let language: String?
    public let lastpoll: String?
    public let generator: String?
    public let userId: Int?
    public let categories: [Int]?
    public let rank: Int?
    public let urlFyyd: String?
    public let episodeCount: Int?
    public let tcolor: String?
    public let color: String?
    public let iflags: String?
    public let paymentURL: String?
    public let stats: FyydStats?
    public let episodes: [FyydEpisode]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case author
        case lastpub
        case description
        case imgURL
        case xmlURL
        case htmlURL
        case status
        case slug
        case layoutImageURL
        case thumbImageURL
        case smallImageURL
        case microImageURL
        case language
        case lastpoll
        case generator
        case userId = "user_id"
        case categories
        case rank
        case urlFyyd = "url_fyyd"
        case episodeCount = "episode_count"
        case tcolor
        case color
        case iflags
        case paymentURL
        case stats
        case episodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeFlexibleInt(forKey: .id)
        title = try container.decodeFlexibleStringIfPresent(forKey: .title)
        subtitle = try container.decodeFlexibleStringIfPresent(forKey: .subtitle) ?? ""
        author = try container.decodeFlexibleStringIfPresent(forKey: .author)
        lastpub = try container.decodeFlexibleStringIfPresent(forKey: .lastpub) ?? ""
        description = try container.decodeFlexibleStringIfPresent(forKey: .description)
        imgURL = try container.decodeFlexibleStringIfPresent(forKey: .imgURL)
        xmlURL = try container.decodeFlexibleStringIfPresent(forKey: .xmlURL)
        htmlURL = try container.decodeFlexibleStringIfPresent(forKey: .htmlURL)
        status = try container.decodeFlexibleIntIfPresent(forKey: .status)
        slug = try container.decodeFlexibleStringIfPresent(forKey: .slug)
        layoutImageURL = try container.decodeFlexibleStringIfPresent(forKey: .layoutImageURL)
        thumbImageURL = try container.decodeFlexibleStringIfPresent(forKey: .thumbImageURL)
        smallImageURL = try container.decodeFlexibleStringIfPresent(forKey: .smallImageURL)
        microImageURL = try container.decodeFlexibleStringIfPresent(forKey: .microImageURL)
        language = try container.decodeFlexibleStringIfPresent(forKey: .language)
        lastpoll = try container.decodeFlexibleStringIfPresent(forKey: .lastpoll)
        generator = try container.decodeFlexibleStringIfPresent(forKey: .generator)
        userId = try container.decodeFlexibleIntIfPresent(forKey: .userId)
        categories = try container.decodeFlexibleIntArrayIfPresent(forKey: .categories)
        rank = try container.decodeFlexibleIntIfPresent(forKey: .rank)
        urlFyyd = try container.decodeFlexibleStringIfPresent(forKey: .urlFyyd)
        episodeCount = try container.decodeFlexibleIntIfPresent(forKey: .episodeCount)
        tcolor = try container.decodeFlexibleStringIfPresent(forKey: .tcolor)
        color = try container.decodeFlexibleStringIfPresent(forKey: .color)
        iflags = try container.decodeFlexibleStringIfPresent(forKey: .iflags)
        paymentURL = try container.decodeFlexibleStringIfPresent(forKey: .paymentURL)
        stats = try container.decodeIfPresent(FyydStats.self, forKey: .stats)
        episodes = try container.decodeIfPresent([FyydEpisode].self, forKey: .episodes)
    }
}

public struct FyydEpisode: Decodable, Sendable, Equatable {
    public let id: Int
    public let title: String
    public let guid: String?
    public let url: String?
    public let audioUrl: String
    public let podcastId: Int
    public let imgURL: String?
    public let pubdate: String?
    public let duration: Int?
    public let status: Int?
    public let numSeason: Int?
    public let numEpisode: Int?
    public let inserted: String?
    public let favedDate: String?
    public let urlFyyd: String?
    public let description: String?
    public let chapters: [FyydChapter]?
    public let contentType: String?
    public let why: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case guid
        case url
        case audioUrl = "enclosure"
        case podcastId = "podcast_id"
        case imgURL
        case pubdate
        case duration
        case status
        case numSeason = "num_season"
        case numEpisode = "num_episode"
        case inserted
        case favedDate
        case urlFyyd = "url_fyyd"
        case description
        case chapters
        case contentType = "content_type"
        case why
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeFlexibleInt(forKey: .id)
        title = try container.decodeFlexibleStringIfPresent(forKey: .title) ?? ""
        guid = try container.decodeFlexibleStringIfPresent(forKey: .guid)
        url = try container.decodeFlexibleStringIfPresent(forKey: .url)
        audioUrl = try container.decodeFlexibleStringIfPresent(forKey: .audioUrl) ?? ""
        podcastId = try container.decodeFlexibleIntIfPresent(forKey: .podcastId) ?? 0
        imgURL = try container.decodeFlexibleStringIfPresent(forKey: .imgURL)
        pubdate = try container.decodeFlexibleStringIfPresent(forKey: .pubdate)
        duration = try container.decodeFlexibleIntIfPresent(forKey: .duration)
        status = try container.decodeFlexibleIntIfPresent(forKey: .status)
        numSeason = try container.decodeFlexibleIntIfPresent(forKey: .numSeason)
        numEpisode = try container.decodeFlexibleIntIfPresent(forKey: .numEpisode)
        inserted = try container.decodeFlexibleStringIfPresent(forKey: .inserted)
        favedDate = try container.decodeFlexibleStringIfPresent(forKey: .favedDate)
        urlFyyd = try container.decodeFlexibleStringIfPresent(forKey: .urlFyyd)
        description = try container.decodeFlexibleStringIfPresent(forKey: .description)
        chapters = try container.decodeIfPresent([FyydChapter].self, forKey: .chapters)
        contentType = try container.decodeFlexibleStringIfPresent(forKey: .contentType)
        why = try container.decodeFlexibleStringIfPresent(forKey: .why)
    }
}

public struct FyydCategory: Decodable, Sendable, Hashable {
    public let id: Int
    public let slug: String
    public let name: String
    public let nameDe: String?
    public let subcategories: [FyydCategory]?

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case nameDe = "name_de"
        case subcategories
    }
}

public struct FyydCuration: Decodable, Sendable, Equatable {
    public let title: String
    public let id: Int
    public let description: String?
    public let layoutImageURL: String?
    public let thumbImageURL: String?
    public let smallImageURL: String?
    public let microImageURL: String?
    public let isPublic: Int?
    public let type: Int?
    public let slug: String?
    public let userId: Int?
    public let url: String?
    public let xmlURL: String?
    public let categories: [Int]?
    public let episodes: [FyydEpisode]?

    enum CodingKeys: String, CodingKey {
        case title
        case id
        case description
        case layoutImageURL
        case thumbImageURL
        case smallImageURL
        case microImageURL
        case isPublic = "public"
        case type
        case slug
        case userId = "user_id"
        case url
        case xmlURL
        case categories
        case episodes
    }
}

public struct FyydCollection: Decodable, Sendable, Equatable {
    public let title: String
    public let id: Int
    public let description: String?
    public let layoutImageURL: String?
    public let thumbImageURL: String?
    public let smallImageURL: String?
    public let microImageURL: String?
    public let isPublic: Int?
    public let slug: String?
    public let userId: Int?
    public let url: String?
    public let podcasts: [FyydPodcast]?

    enum CodingKeys: String, CodingKey {
        case title
        case id
        case description
        case layoutImageURL
        case thumbImageURL
        case smallImageURL
        case microImageURL
        case isPublic = "public"
        case slug
        case userId = "user_id"
        case url
        case podcasts
    }
}

public struct FyydAlert: Decodable, Sendable, Equatable {
    public let id: Int
    public let term: String
    public let slug: String?
    public let lastcheck: String?
    public let dirty: Int?
    public let dirtyFeed: Int?
    public let active: Int?
    public let schedule: Int?
    public let episodes: [FyydEpisode]?

    enum CodingKeys: String, CodingKey {
        case id
        case term
        case slug
        case lastcheck
        case dirty
        case dirtyFeed = "dirty_feed"
        case active
        case schedule
        case episodes
    }
}

public struct FyydStateChange: Decodable, Sendable, Equatable {
    public let state: Int?
    public let text: String?

    public var isActive: Bool? {
        state.map { $0 != 0 }
    }
}

public enum FyydObjectType: String, Sendable {
    case episode
    case podcast
    case curation
    case collection
    case user
}

public enum FyydOwnedPodcastAction: String, Sendable {
    case check
}

public enum FyydError: Error {
    case invalidURL
    case notAuthenticated
    case noRefreshToken
    case invalidResponse
    case notConfigured
    case httpError(statusCode: Int, message: String?)
}

struct FyydMetaInfo: Decodable, Sendable {
    let API_INFO: FyydAPIInfo?
    let paging: PagingInfo?
}

struct FyydAPIInfo: Decodable, Sendable {
    let API_VERSION: String?
}

struct FyydEnvelope<T: Decodable>: Decodable {
    let status: Int?
    let msg: String?
    let meta: FyydMetaInfo?
    let data: T
}

struct FyydAPIErrorEnvelope: Decodable {
    let errors: FyydAPIErrorPayload?
}

struct FyydAPIErrorPayload: Decodable {
    let code: Int?
    let message: String?
    let httpCode: Int?
    let httpMessage: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case httpCode = "http_code"
        case httpMessage = "http_message"
    }
}

struct FyydCategoryPodcastsPayload: Decodable {
    let category: FyydCategorySummary?
    let parent: FyydCategorySummary?
    let podcasts: [FyydPodcast]
}

struct FyydCategoryCurationsPayload: Decodable {
    let category: FyydCategorySummary?
    let parent: FyydCategorySummary?
    let curations: [FyydCuration]
}

private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try decodeFlexibleIntIfPresent(forKey: key) {
            return value
        }

        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected an integer-compatible value.")
    }

    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        guard contains(key) else {
            return nil
        }

        if let value = try? decode(Int.self, forKey: key) {
            return value
        }

        if let value = try? decode(String.self, forKey: key) {
            return Int(value)
        }

        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }

        return nil
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        guard contains(key) else {
            return nil
        }

        if let value = try? decode(String.self, forKey: key) {
            return value
        }

        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }

        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }

        return nil
    }

    func decodeFlexibleIntArrayIfPresent(forKey key: Key) throws -> [Int]? {
        guard contains(key) else {
            return nil
        }

        if let value = try? decode([Int].self, forKey: key) {
            return value
        }

        if let value = try? decode([String].self, forKey: key) {
            return value.compactMap(Int.init)
        }

        if let value = try? decode(Int.self, forKey: key) {
            return [value]
        }

        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return [intValue]
        }

        return nil
    }
}
