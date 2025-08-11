import Foundation

@available(iOS 16, *)
public actor FyydSearchManager {
    private let baseURL = "https://api.fyyd.de"
    private var selectedLanguage: String = "en" // Keep language inside the actor
    
    // Optional OAuth2 configuration
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpirationDate: Date?
    private var clientId: String?
    private var clientSecret: String?
    private var redirectURI: String?
    private let authEndpoint = "https://fyyd.de/oauth/authorize"
    private let tokenEndpoint = "https://fyyd.de/oauth/token"
    
    // Default initializer for unauthenticated access
    public init() {
    }
    
    // Initializer for authenticated access
    public init(clientId: String, clientSecret: String, redirectURI: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }
    
    public func setLanguage(_ language: String) {
        print("set language to \(language)")
        self.selectedLanguage = language
    }
    
    // MARK: - Private Helper Struct for category podcasts
    
    private struct _FyydCategoryPodcastsResponse: Decodable {
        let status: Int
        let msg: String?
        let meta: FyydMetaInfo?
        let data: _Data
        struct _Data: Decodable {
            let podcasts: [FyydPodcast]
        }
    }
    
    public struct FyydPodcastListWithPaging: Sendable {
        public let podcasts: [FyydPodcast]
        public let paging: PagingInfo?
    }
    
    // MARK: - Public API Methods
    
    /// Fetch hot podcasts
    public func getHotPodcasts(lang: String? = nil, count: Int = 10) async -> [FyydPodcast]? {
        let langQuery = lang ?? selectedLanguage ?? "en"

        return await fetchPodcasts(from: "/0.2/feature/podcast/hot", params: ["count": "\(count)", "language": langQuery])?.podcasts
    }

    /// Search podcasts
    public func searchPodcasts(query: String, count: Int = 100) async -> [FyydPodcast]? {
    
        return await fetchPodcasts(from: "/0.2/search/podcast", params: ["title": query, "count": "\(count)"])?.podcasts
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
        return await fetchPodcasts(from: "/0.2/feature/podcast/recommend", params: ["count": "\(count)"])?.podcasts
    }
    
    /// Fetch podcast categories
    public func getCategories() async -> [FyydCategory]? {
        return await fetchCategories(from: "/0.2/categories")
    }

    /// Fetch podcasts by category ID
    /// - Parameters:
    ///   - id: Category ID
    ///   - count: Number of podcasts to fetch
    ///   - page: Page number for pagination
    /// - Returns: Podcasts with paging information
    public func getPodcastsByCategory(id: Int, count: Int = 10, page: Int? = nil) async -> FyydPodcastListWithPaging? {
        return await fetchPodcasts(from: "/0.2/category", params: ["category_id": "\(id)", "count": "\(count)"], page: page)
    }
    
    /// Fetch discoverable podcasts
    public func getDiscoverPodcasts(count: Int = 10) async -> [FyydPodcast]? {
        return await fetchPodcasts(from: "/0.2/discover/podlist", params: ["count": "\(count)"])?.podcasts
    }

    /// Fetch available languages
    public func getLanguages() async -> [String]? {
        return await fetchLanguages(from: "/0.2/feature/podcast/hot/languages")
    }
    
    // MARK: - OAuth2 Methods
    
    /// Get the authorization URL for OAuth2 flow
    public func getAuthorizationURL() -> URL? {
        guard let clientId = clientId, let redirectURI = redirectURI else {
            return nil
        }
        
        var components = URLComponents(string: authEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read write")
        ]
        return components?.url
    }
    
    /// Exchange authorization code for access token
    public func exchangeCodeForToken(code: String) async throws {
        guard let clientId = clientId,
              let clientSecret = clientSecret,
              let redirectURI = redirectURI else {
            throw FyydError.notConfigured
        }
        
        guard let url = URL(string: tokenEndpoint) else {
            throw FyydError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    }
    
    /// Refresh the access token using the refresh token
    private func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken,
              let clientId = clientId,
              let clientSecret = clientSecret else {
            throw FyydError.noRefreshToken
        }
        
        guard let url = URL(string: tokenEndpoint) else {
            throw FyydError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    }
    
    /// Check if the current token is valid and refresh if necessary
    private func ensureValidToken() async throws {
        // If not configured for OAuth2, skip token validation
        guard clientId != nil else { return }
        
        guard let expirationDate = tokenExpirationDate else {
            throw FyydError.notAuthenticated
        }
        
        if Date() >= expirationDate {
            try await refreshAccessToken()
        }
    }
    
    /// Handle the OAuth2 redirect URL and extract the authorization code
    /// - Parameter url: The URL received from the OAuth2 redirect
    /// - Throws: FyydError.invalidResponse if the URL doesn't contain a valid authorization code
    public func handleRedirect(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw FyydError.invalidResponse
        }
        
        try await exchangeCodeForToken(code: code)
    }
    
    // MARK: - Private Helper Methods
    
    /// Generic function to fetch a list of podcasts with optional paging
    private func fetchPodcasts(from endpoint: String, params: [String: String] = [:], page: Int? = nil) async -> FyydPodcastListWithPaging? {
        var allParams = params
        if let page = page {
            allParams["page"] = "\(page)"
        }
        guard let url = buildURL(endpoint: endpoint, params: allParams) else { return nil }
        do {
            try await ensureValidToken()
            var request = URLRequest(url: url)
            
            // Only add authorization header if we have a token
            if let accessToken = accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            if endpoint == "/0.2/category" {
                let response = try JSONDecoder().decode(_FyydCategoryPodcastsResponse.self, from: data)
                let paging = response.meta?.paging
                return FyydPodcastListWithPaging(podcasts: response.data.podcasts, paging: paging)
            } else {
                let response = try JSONDecoder().decode(FyydPodcastResponse.self, from: data)
                return FyydPodcastListWithPaging(podcasts: response.data, paging: nil)
            }
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
    let msg: String?
    let meta: FyydMetaInfo?
    let data: [FyydCategory]
}

struct FyydMetaInfo: Decodable, Sendable {
    let API_INFO: FyydAPIInfo?
    let paging: PagingInfo?
}

struct FyydAPIInfo: Decodable, Sendable {
    let API_VERSION: String?
}

public struct PagingInfo: Decodable, Sendable {
    public let count: Int?
    public let page: Int?
    public let first_page: Int?
    public let last_page: Int?
    public let next_page: Int?
    public let prev_page: Int?
}

public struct FyydLanguagesResponse: Decodable, Sendable {
    let status: Int
    let data: [String]
}

// MARK: - Example Model Definitions

public struct FyydPodcast: Decodable, Sendable, Equatable {
    public let id: Int
    public let title: String?
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

public struct FyydCategory: Decodable, Sendable, Hashable {
    public let id: Int
    public let slug: String
    public let name: String
    public let name_de: String?
    public let subcategories: [FyydCategory]?
}

// MARK: - Error Types

public enum FyydError: Error {
    case invalidURL
    case notAuthenticated
    case noRefreshToken
    case invalidResponse
    case notConfigured
}

// MARK: - OAuth2 Response Models

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
