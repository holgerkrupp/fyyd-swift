import Foundation

@available(iOS 16, *)
public actor FyydSearchManager {
    private let baseURL = "https://api.fyyd.de"
    private var selectedLanguage: String = "en" // Keep language inside the actor

    public func setLanguage(_ language: String) {
        self.selectedLanguage = language
    }

    public init() {
        
    }
    
    // MARK: - Public API Methods
    
    /// Fetch hot podcasts
    public func getHotPodcasts(lang: String? = nil, count: Int = 10) async -> [FyydPodcast]? {
        let langQuery = lang ?? selectedLanguage ?? "en"

        return await fetchPodcasts(from: "/0.2/feature/podcast/hot", params: ["count": "\(count)", "language": langQuery])
    }

    /// Search podcasts
    public func searchPodcasts(query: String, count: Int = 10) async -> [FyydPodcast]? {
    
        return await fetchPodcasts(from: "/0.2/search/podcast", params: ["title": query, "count": "\(count)"])
    }
    
    /// Fetch podcast details by ID
    public func getPodcastDetails(id: Int) async -> FyydPodcast? {
        return await fetchSinglePodcast(from: "/0.2/podcast", params: ["podcast_id": "\(id)"])
    }
    
    /// Fetch recent episodes
    public func getRecentEpisodes(count: Int = 10) async -> [FyydEpisode]? {
        return await fetchEpisodes(from: "/0.2/feature/episode/recent", params: ["count": "\(count)"])
    }

    /// Fetch podcast recommendations
    public func getPodcastRecommendations(count: Int = 10) async -> [FyydPodcast]? {
        return await fetchPodcasts(from: "/0.2/feature/podcast/recommendation", params: ["count": "\(count)"])
    }
    
    /// Fetch podcast categories
    public func getCategories() async -> [FyydCategory]? {
        return await fetchCategories(from: "/0.2/category/list")
    }

    /// Fetch podcasts by category ID
    public func getPodcastsByCategory(id: Int, count: Int = 10) async -> [FyydPodcast]? {
        return await fetchPodcasts(from: "/0.2/category", params: ["category_id": "\(id)", "count": "\(count)"])
    }
    
    /// Fetch discoverable podcasts
    public func getDiscoverPodcasts(count: Int = 10) async -> [FyydPodcast]? {
        return await fetchPodcasts(from: "/0.2/discover/podlist", params: ["count": "\(count)"])
    }

    /// Fetch available languages
    public func getLanguages() async -> [String]? {
        return await fetchLanguages(from: "/0.2/feature/podcast/hot/languages")
    }
    
    // MARK: - Private Helper Methods
    
    /// Generic function to fetch a list of podcasts

private func fetchPodcasts(from endpoint: String, params: [String: String] = [:]) async -> [FyydPodcast]? {
        guard let url = buildURL(endpoint: endpoint, params: params) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
   
            let response = try JSONDecoder().decode(FyydPodcastResponse.self, from: data)
            return response.data
        } catch {
            print("Error fetching podcasts: \(error)")
            return nil
        }
    }

    /// Fetch details for a single podcast
    private func fetchSinglePodcast(from endpoint: String, params: [String: String] = [:]) async -> FyydPodcast? {
        guard let url = buildURL(endpoint: endpoint, params: params) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FyydPodcastResponse.self, from: data)
            return response.data.first
        } catch {
            print("Error fetching podcast details: \(error)")
            return nil
        }
    }
    
    /// Fetch a list of episodes
    private func fetchEpisodes(from endpoint: String, params: [String: String] = [:]) async -> [FyydEpisode]? {
        guard let url = buildURL(endpoint: endpoint, params: params) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FyydEpisodeResponse.self, from: data)
            return response.data
        } catch {
            print("Error fetching episodes: \(error)")
            return nil
        }
    }

    /// Fetch podcast categories
    private func fetchCategories(from endpoint: String) async -> [FyydCategory]? {
        guard let url = buildURL(endpoint: endpoint) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FyydCategoryResponse.self, from: data)
            return response.data
        } catch {
            print("Error fetching categories: \(error)")
            return nil
        }
    }

    /// Fetch list of supported languages
    private func fetchLanguages(from endpoint: String) async -> [String]? {
        guard let url = buildURL(endpoint: endpoint) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
           
            let response = try JSONDecoder().decode(FyydLanguagesResponse.self, from: data)
            return response.data
        } catch {
            print("Error fetching languages: \(error)")
            return nil
        }
    }
    
    /// Construct a URL with query parameters
    private func buildURL(endpoint: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }
}

// MARK: - Data Models

public struct FyydPodcastResponse: Decodable, Sendable {
    let status: Int
    let data: [FyydPodcast]
}

public struct FyydEpisodeResponse: Decodable, Sendable {
    let status: Int
    let data: [FyydEpisode]
}

public struct FyydCategoryResponse: Decodable, Sendable {
    let status: Int
    let data: [FyydCategory]
}

public struct FyydLanguagesResponse: Decodable, Sendable {
    let status: Int
    let data: [String]
}

// MARK: - Example Model Definitions

public struct FyydPodcast: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let author: String?
    public let lastpub: String
    public let description: String?
    public let imgURL: String?
    public let xmlURL: String?
}

public struct FyydEpisode: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let podcastId: Int
    public let audioUrl: String
    public let duration: Int?
}

public struct FyydCategory: Decodable, Sendable {
    let id: Int
    let title: String
}
