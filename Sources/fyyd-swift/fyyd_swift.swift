import Foundation

@available(iOS 16, macOS 12, *)
public actor FyydSearchManager {
    private let baseURL = "https://api.fyyd.de"
    private var selectedLanguage = "en"

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpirationDate: Date?
    private var clientId: String?
    private var clientSecret: String?
    private var redirectURI: String?

    private let authEndpoint = "https://fyyd.de/oauth/authorize"
    private let tokenEndpoint = "https://fyyd.de/oauth/token"
    private let decoder = JSONDecoder()

    public init() {}

    public init(clientId: String, clientSecret: String, redirectURI: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }

    public func setLanguage(_ language: String) {
        selectedLanguage = language
    }

    public func setAccessToken(_ token: String, refreshToken: String? = nil, expiresIn: Int? = nil) {
        accessToken = token
        self.refreshToken = refreshToken
        tokenExpirationDate = expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
    }

    public func clearAuthentication() {
        accessToken = nil
        refreshToken = nil
        tokenExpirationDate = nil
    }

    public func isAuthenticated() -> Bool {
        accessToken != nil
    }

    public func getHotPodcasts(lang: String? = nil, count: Int = 10) async -> [FyydPodcast]? {
        let language = lang ?? selectedLanguage
        return await fetchList(from: "/0.2/feature/podcast/hot", params: [
            "count": "\(count)",
            "language": language
        ])
    }

    public func searchPodcasts(query: String, count: Int = 100) async -> [FyydPodcast]? {
        await searchPodcasts(title: query, count: count)
    }

    public func getPodcastDetails(id: Int) async -> FyydPodcast? {
        (await getPodcast(podcastID: id))?.podcast
    }

    public func getRecentEpisodes(count: Int = 10) async -> [FyydEpisode]? {
        await getLatestEpisodes(count: count)
    }

    public func getPodcastRecommendations(count: Int = 10) async -> [FyydPodcast]? {
        await fetchList(from: "/0.2/feature/podcast/recommend", params: [
            "count": "\(count)"
        ])
    }

    public func getCategories() async -> [FyydCategory]? {
        await fetchList(from: "/0.2/categories")
    }

    public func getPodcastsByCategory(id: Int, count: Int = 10, page: Int? = nil) async -> FyydPodcastListWithPaging? {
        guard let result = await getCategoryPodcasts(categoryID: id, count: count, page: page ?? 0) else {
            return nil
        }

        return FyydPodcastListWithPaging(podcasts: result.podcasts, paging: result.paging)
    }

    public func getDiscoverPodcasts(count: Int = 10) async -> [FyydPodcast]? {
        await fetchList(from: "/0.2/discover/podlist", params: [
            "count": "\(count)"
        ])
    }

    public func getLanguages() async -> [String]? {
        await fetchList(from: "/0.2/feature/podcast/hot/languages")
    }

    public func getAccountInfo() async -> FyydUser? {
        await fetchObject(from: "/0.2/account/info", requiresAuth: true)
    }

    public func getAccountCurations() async -> [FyydCuration]? {
        await fetchList(from: "/0.2/account/curations", requiresAuth: true)
    }

    public func getAccountCollections() async -> [FyydCollection]? {
        await fetchList(from: "/0.2/account/collections", requiresAuth: true)
    }

    public func getUser(userID: Int? = nil, nick: String? = nil) async -> FyydUser? {
        guard let params = userParameters(userID: userID, nick: nick) else {
            return nil
        }

        return await fetchObject(from: "/0.2/user", params: params)
    }

    public func getUserCurations(userID: Int? = nil, nick: String? = nil, includeEpisodes: Bool = false) async -> [FyydCuration]? {
        guard let params = userParameters(userID: userID, nick: nick) else {
            return nil
        }

        let endpoint = includeEpisodes ? "/0.2/user/curations/episodes" : "/0.2/user/curations"
        return await fetchList(from: endpoint, params: params)
    }

    public func getUserCollections(userID: Int? = nil, nick: String? = nil, includePodcasts: Bool = false) async -> [FyydCollection]? {
        guard let params = userParameters(userID: userID, nick: nick) else {
            return nil
        }

        let endpoint = includePodcasts ? "/0.2/user/collections/podcasts" : "/0.2/user/collections"
        return await fetchList(from: endpoint, params: params)
    }

    public func createAction(objectID: Int, objectType: FyydObjectType, actionName: String, metadata: String? = nil) async -> Bool {
        await postNoContent(
            to: "/0.2/action",
            params: [
                "object_id": "\(objectID)",
                "object_type": objectType.rawValue,
                "action": actionName,
                "metadata": metadata
            ],
            requiresAuth: true
        )
    }

    public func deleteAction(actionID: Int) async -> Bool {
        await postNoContent(
            to: "/0.2/action/delete",
            params: ["action_id": "\(actionID)"],
            requiresAuth: true
        )
    }

    public func getActions(
        objectID: Int? = nil,
        objectType: FyydObjectType? = nil,
        actionName: String? = nil,
        metadata: String? = nil,
        dateStart: String? = nil,
        dateEnd: String? = nil
    ) async -> [FyydAction]? {
        await fetchList(
            from: "/0.2/action",
            params: [
                "object_id": objectID.map(String.init),
                "object_type": objectType?.rawValue,
                "action": actionName,
                "metadata": metadata,
                "date_start": dateStart,
                "date_end": dateEnd
            ],
            requiresAuth: true
        )
    }

    public func getPodcast(
        podcastID: Int? = nil,
        podcastSlug: String? = nil,
        includeEpisodes: Bool = false,
        page: Int? = nil,
        count: Int = 50
    ) async -> FyydPodcastDetails? {
        guard var params = podcastParameters(podcastID: podcastID, podcastSlug: podcastSlug) else {
            return nil
        }

        params["count"] = "\(count)"
        params["page"] = page.map(String.init)

        let endpoint = includeEpisodes ? "/0.2/podcast/episodes" : "/0.2/podcast"
        guard let (podcast, meta) = await fetchData(FyydPodcast.self, from: endpoint, params: params) else {
            return nil
        }

        return FyydPodcastDetails(podcast: podcast, paging: meta?.paging)
    }

    public func getPodcastSeason(
        podcastID: Int? = nil,
        podcastSlug: String? = nil,
        seasonNumber: Int,
        episodeNumber: Int? = nil,
        page: Int? = nil,
        count: Int = 50
    ) async -> FyydPodcastDetails? {
        guard var params = podcastParameters(podcastID: podcastID, podcastSlug: podcastSlug) else {
            return nil
        }

        params["season_number"] = "\(seasonNumber)"
        params["episode_number"] = episodeNumber.map(String.init)
        params["page"] = page.map(String.init)
        params["count"] = "\(count)"

        guard let (podcast, meta) = await fetchData(FyydPodcast.self, from: "/0.2/podcast/season", params: params) else {
            return nil
        }

        return FyydPodcastDetails(podcast: podcast, paging: meta?.paging)
    }

    public func performPodcastAction(
        podcastID: Int? = nil,
        podcastSlug: String? = nil,
        action: FyydOwnedPodcastAction = .check
    ) async -> Bool {
        guard var params = podcastParameters(podcastID: podcastID, podcastSlug: podcastSlug) else {
            return false
        }

        params["action"] = action.rawValue
        return await postNoContent(to: "/0.2/podcast/action", params: params, requiresAuth: true)
    }

    public func getPodcasts(page: Int = 0, count: Int = 50) async -> FyydPodcastListWithPaging? {
        guard let (podcasts, meta) = await fetchData(
            [FyydPodcast].self,
            from: "/0.2/podcasts",
            params: ["page": "\(page)", "count": "\(count)"]
        ) else {
            return nil
        }

        return FyydPodcastListWithPaging(podcasts: podcasts, paging: meta?.paging)
    }

    public func getLatestPodcasts(sinceID: Int? = nil, count: Int = 20) async -> [FyydPodcast]? {
        await fetchList(
            from: "/0.2/podcast/latest",
            params: [
                "since_id": sinceID.map(String.init),
                "count": "\(count)"
            ]
        )
    }

    public func getCategoryPodcasts(categoryID: Int, count: Int = 50, page: Int = 0) async -> FyydCategoryPodcastsPage? {
        guard let (payload, meta) = await fetchData(
            FyydCategoryPodcastsPayload.self,
            from: "/0.2/category",
            params: [
                "category_id": "\(categoryID)",
                "page": "\(page)",
                "count": "\(count)"
            ]
        ) else {
            return nil
        }

        return FyydCategoryPodcastsPage(
            category: payload.category,
            parent: payload.parent,
            podcasts: payload.podcasts,
            paging: meta?.paging
        )
    }

    public func getPodcastRecommendations(forPodcastID podcastID: Int? = nil, podcastSlug: String? = nil, count: Int = 10) async -> [FyydPodcast]? {
        guard var params = podcastParameters(podcastID: podcastID, podcastSlug: podcastSlug) else {
            return nil
        }

        params["count"] = "\(count)"
        return await fetchList(from: "/0.2/podcast/recommend", params: params)
    }

    public func getPodcastCollections(
        podcastID: Int? = nil,
        podcastSlug: String? = nil,
        count: Int = 10,
        page: Int = 0
    ) async -> FyydCollectionListWithPaging? {
        guard var params = podcastParameters(podcastID: podcastID, podcastSlug: podcastSlug) else {
            return nil
        }

        params["count"] = "\(count)"
        params["page"] = "\(page)"

        guard let (collections, meta) = await fetchData([FyydCollection].self, from: "/0.2/podcast/collections", params: params) else {
            return nil
        }

        return FyydCollectionListWithPaging(collections: collections, paging: meta?.paging)
    }

    public func getEpisode(id: Int) async -> FyydEpisode? {
        await fetchObject(from: "/0.2/episode", params: ["episode_id": "\(id)"])
    }

    public func getLatestEpisodes(sinceID: Int? = nil, count: Int = 20) async -> [FyydEpisode]? {
        await fetchList(
            from: "/0.2/episode/latest",
            params: [
                "since_id": sinceID.map(String.init),
                "count": "\(count)"
            ]
        )
    }

    public func getEpisodeCurations(episodeID: Int, count: Int = 10, page: Int = 0) async -> FyydCurationListWithPaging? {
        guard let (curations, meta) = await fetchData(
            [FyydCuration].self,
            from: "/0.2/episode/curations",
            params: [
                "episode_id": "\(episodeID)",
                "count": "\(count)",
                "page": "\(page)"
            ]
        ) else {
            return nil
        }

        return FyydCurationListWithPaging(curations: curations, paging: meta?.paging)
    }

    public func getCuration(id: Int, includeEpisodes: Bool = false) async -> FyydCuration? {
        let endpoint = includeEpisodes ? "/0.2/curation/episodes" : "/0.2/curation"
        return await fetchObject(from: endpoint, params: ["curation_id": "\(id)"])
    }

    public func saveCuration(
        curationID: Int? = nil,
        title: String? = nil,
        description: String? = nil,
        slug: String? = nil,
        isPublic: Bool? = nil,
        categoryIDs: [Int]? = nil,
        image: FyydUploadImage? = nil
    ) async -> FyydCuration? {
        guard curationID != nil || (title?.isEmpty == false) else {
            print("fyyd request failed for /0.2/curation: title is required when creating a curation.")
            return nil
        }

        return await postObject(
            to: "/0.2/curation",
            params: [
                "curation_id": curationID.map(String.init),
                "title": title,
                "description": description,
                "slug": slug,
                "public": boolParameter(isPublic),
                "categories": jsonArrayString(from: categoryIDs)
            ],
            requiresAuth: true,
            image: image
        )
    }

    public func deleteCuration(id: Int) async -> Bool {
        await postNoContent(
            to: "/0.2/curation/delete",
            params: ["curation_id": "\(id)"],
            requiresAuth: true
        )
    }

    public func curate(curationID: Int, episodeID: Int, why: String? = nil, forceState: Bool? = nil) async -> FyydStateChange? {
        await postObject(
            to: "/0.2/curate",
            params: [
                "curation_id": "\(curationID)",
                "episode_id": "\(episodeID)",
                "why": why,
                "force_state": boolParameter(forceState)
            ],
            requiresAuth: true
        )
    }

    public func getCurateState(curationID: Int, episodeID: Int) async -> FyydStateChange? {
        await fetchObject(
            from: "/0.2/curate",
            params: [
                "curation_id": "\(curationID)",
                "episode_id": "\(episodeID)"
            ],
            requiresAuth: true
        )
    }

    public func getCurationsByCategory(
        categoryID: Int? = nil,
        categorySlug: String? = nil,
        count: Int = 50,
        page: Int = 0
    ) async -> FyydCategoryCurationsPage? {
        guard var params = categoryParameters(categoryID: categoryID, categorySlug: categorySlug) else {
            return nil
        }

        params["count"] = "\(count)"
        params["page"] = "\(page)"

        guard let (payload, meta) = await fetchData(
            FyydCategoryCurationsPayload.self,
            from: "/0.2/category/curation",
            params: params
        ) else {
            return nil
        }

        return FyydCategoryCurationsPage(
            category: payload.category,
            parent: payload.parent,
            curations: payload.curations,
            paging: meta?.paging
        )
    }

    public func getCollection(id: Int, includePodcasts: Bool = false) async -> FyydCollection? {
        let endpoint = includePodcasts ? "/0.2/collection/podcasts" : "/0.2/collection"
        return await fetchObject(from: endpoint, params: ["collection_id": "\(id)"])
    }

    public func saveCollection(
        collectionID: Int? = nil,
        title: String? = nil,
        description: String? = nil,
        slug: String? = nil,
        isPublic: Bool? = nil,
        image: FyydUploadImage? = nil
    ) async -> FyydCollection? {
        guard collectionID != nil || (title?.isEmpty == false) else {
            print("fyyd request failed for /0.2/collection: title is required when creating a collection.")
            return nil
        }

        return await postObject(
            to: "/0.2/collection",
            params: [
                "collection_id": collectionID.map(String.init),
                "title": title,
                "description": description,
                "slug": slug,
                "public": boolParameter(isPublic)
            ],
            requiresAuth: true,
            image: image
        )
    }

    public func deleteCollection(id: Int) async -> Bool {
        await postNoContent(
            to: "/0.2/collection/delete",
            params: ["collection_id": "\(id)"],
            requiresAuth: true
        )
    }

    public func collect(collectionID: Int, podcastID: Int, forceState: Bool? = nil) async -> FyydStateChange? {
        await postObject(
            to: "/0.2/collect",
            params: [
                "collection_id": "\(collectionID)",
                "podcast_id": "\(podcastID)",
                "force_state": boolParameter(forceState)
            ],
            requiresAuth: true
        )
    }

    public func getCollectState(collectionID: Int, podcastID: Int) async -> FyydStateChange? {
        await fetchObject(
            from: "/0.2/collect",
            params: [
                "collection_id": "\(collectionID)",
                "podcast_id": "\(podcastID)"
            ],
            requiresAuth: true
        )
    }

    public func getAlert(id: Int, includeEpisodes: Bool = false) async -> FyydAlert? {
        let endpoint = includeEpisodes ? "/0.2/alert/episodes" : "/0.2/alert"
        return await fetchObject(from: endpoint, params: ["alert_id": "\(id)"])
    }

    public func saveAlert(alertID: Int? = nil, term: String? = nil, slug: String? = nil) async -> FyydAlert? {
        guard alertID != nil || (term?.isEmpty == false) else {
            print("fyyd request failed for /0.2/alert: term is required when creating an alert.")
            return nil
        }

        return await postObject(
            to: "/0.2/alert",
            params: [
                "alert_id": alertID.map(String.init),
                "term": term,
                "slug": slug
            ],
            requiresAuth: true
        )
    }

    public func deleteAlert(id: Int) async -> Bool {
        await postNoContent(
            to: "/0.2/alert/delete",
            params: ["alert_id": "\(id)"],
            requiresAuth: true
        )
    }

    public func searchEpisodes(
        title: String? = nil,
        guid: String? = nil,
        podcastID: Int? = nil,
        podcastTitle: String? = nil,
        pubdate: String? = nil,
        duration: Int? = nil,
        url: String? = nil,
        term: String? = nil,
        count: Int = 10
    ) async -> [FyydEpisode]? {
        await fetchList(
            from: "/0.2/search/episode",
            params: [
                "title": title,
                "guid": guid,
                "podcast_id": podcastID.map(String.init),
                "podcast_title": podcastTitle,
                "pubdate": pubdate,
                "duration": duration.map(String.init),
                "url": url,
                "term": term,
                "count": "\(count)"
            ]
        )
    }

    public func searchPodcasts(
        title: String? = nil,
        url: String? = nil,
        term: String? = nil,
        language: String? = nil,
        generator: String? = nil,
        count: Int = 10
    ) async -> [FyydPodcast]? {
        await fetchList(
            from: "/0.2/search/podcast",
            params: [
                "title": title,
                "url": url,
                "term": term,
                "language": language,
                "generator": generator,
                "count": "\(count)"
            ]
        )
    }

    public func searchCurations(categoryID: Int? = nil, term: String? = nil, count: Int = 10) async -> [FyydCuration]? {
        await fetchList(
            from: "/0.2/search/curation",
            params: [
                "category_id": categoryID.map(String.init),
                "term": term,
                "count": "\(count)"
            ]
        )
    }

    public func searchUsers(nick: String? = nil, fullname: String? = nil, count: Int = 10) async -> [FyydUser]? {
        await fetchList(
            from: "/0.2/search/user",
            params: [
                "nick": nick,
                "fullname": fullname,
                "count": "\(count)"
            ]
        )
    }

    public func searchPodcastsByColor(rgb: String, count: Int = 10) async -> [FyydPodcast]? {
        await fetchList(
            from: "/0.2/search/color",
            params: [
                "rgb": rgb,
                "count": "\(count)"
            ]
        )
    }

    public func getAuthorizationURL() -> URL? {
        guard let clientId, let redirectURI else {
            return nil
        }

        var components = URLComponents(string: authEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: "read write")
        ]
        return components?.url
    }

    public func exchangeCodeForToken(code: String) async throws {
        guard let clientId, let clientSecret, let redirectURI else {
            throw FyydError.notConfigured
        }

        let response = try await performTokenRequest(parameters: [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ])

        applyTokenResponse(response)
    }

    public func handleRedirect(url: URL) async throws {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fragmentValues = fragmentParameters(from: components?.fragment)

        if let token = fragmentValues["token"] ?? fragmentValues["access_token"] {
            accessToken = token
            refreshToken = fragmentValues["refresh_token"]
            tokenExpirationDate = fragmentValues["expires_in"]
                .flatMap(Int.init)
                .map { Date().addingTimeInterval(TimeInterval($0)) }
            return
        }

        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            try await exchangeCodeForToken(code: code)
            return
        }

        throw FyydError.invalidResponse
    }

    private func fetchObject<T: Decodable>(
        from endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = false
    ) async -> T? {
        guard let envelope: FyydEnvelope<T> = await fetchEnvelope(from: endpoint, params: params, requiresAuth: requiresAuth) else {
            return nil
        }

        return envelope.data
    }

    private func fetchList<T: Decodable>(
        from endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = false
    ) async -> [T]? {
        guard let envelope: FyydEnvelope<[T]> = await fetchEnvelope(from: endpoint, params: params, requiresAuth: requiresAuth) else {
            return nil
        }

        return envelope.data
    }

    private func fetchData<T: Decodable>(
        _ type: T.Type,
        from endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = false
    ) async -> (T, FyydMetaInfo?)? {
        guard let envelope: FyydEnvelope<T> = await fetchEnvelope(from: endpoint, params: params, requiresAuth: requiresAuth) else {
            return nil
        }

        return (envelope.data, envelope.meta)
    }

    private func fetchEnvelope<T: Decodable>(
        from endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = false
    ) async -> FyydEnvelope<T>? {
        do {
            let (data, _) = try await request(endpoint: endpoint, method: "GET", params: params, requiresAuth: requiresAuth)
            return try decoder.decode(FyydEnvelope<T>.self, from: data)
        } catch {
            log(error, endpoint: endpoint)
            return nil
        }
    }

    private func postObject<T: Decodable>(
        to endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = true,
        image: FyydUploadImage? = nil
    ) async -> T? {
        do {
            let (data, _) = try await request(endpoint: endpoint, method: "POST", params: params, requiresAuth: requiresAuth, image: image)
            let envelope = try decoder.decode(FyydEnvelope<T>.self, from: data)
            return envelope.data
        } catch {
            log(error, endpoint: endpoint)
            return nil
        }
    }

    private func postNoContent(
        to endpoint: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = true
    ) async -> Bool {
        do {
            _ = try await request(endpoint: endpoint, method: "POST", params: params, requiresAuth: requiresAuth)
            return true
        } catch {
            log(error, endpoint: endpoint)
            return false
        }
    }

    private func request(
        endpoint: String,
        method: String,
        params: [String: String?] = [:],
        requiresAuth: Bool = false,
        image: FyydUploadImage? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let sanitizedParams = params.compactMapValues { $0 }
        let urlParams = method == "GET" ? sanitizedParams : [:]

        guard let url = buildURL(endpoint: endpoint, params: urlParams) else {
            throw FyydError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = try await preparedAccessToken(requiresAuth: requiresAuth) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if method != "GET" {
            if let image {
                let boundary = "Boundary-\(UUID().uuidString)"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.httpBody = multipartBody(params: sanitizedParams, image: image, boundary: boundary)
            } else {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = formBodyData(from: sanitizedParams)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FyydError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let apiError = try? decoder.decode(FyydAPIErrorEnvelope.self, from: data)
            throw FyydError.httpError(statusCode: httpResponse.statusCode, message: apiError?.errors?.message)
        }

        return (data, httpResponse)
    }

    private func preparedAccessToken(requiresAuth: Bool) async throws -> String? {
        if clientId != nil, let expirationDate = tokenExpirationDate, Date() >= expirationDate {
            try await refreshAccessToken()
        }

        guard let accessToken else {
            if requiresAuth {
                throw FyydError.notAuthenticated
            }

            return nil
        }

        return accessToken
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken, let clientId, let clientSecret else {
            throw FyydError.noRefreshToken
        }

        let response = try await performTokenRequest(parameters: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ])

        applyTokenResponse(response)
    }

    private func performTokenRequest(parameters: [String: String]) async throws -> TokenResponse {
        guard let url = URL(string: tokenEndpoint) else {
            throw FyydError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBodyData(from: parameters)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw FyydError.invalidResponse
        }

        return try decoder.decode(TokenResponse.self, from: data)
    }

    private func applyTokenResponse(_ response: TokenResponse) {
        accessToken = response.accessToken
        refreshToken = response.refreshToken ?? refreshToken
        tokenExpirationDate = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
    }

    private func buildURL(endpoint: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        if !params.isEmpty {
            components?.queryItems = params.keys.sorted().map { key in
                URLQueryItem(name: key, value: params[key])
            }
        }
        return components?.url
    }

    private func formBodyData(from params: [String: String]) -> Data? {
        var components = URLComponents()
        components.queryItems = params.keys.sorted().map { key in
            URLQueryItem(name: key, value: params[key])
        }
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private func multipartBody(params: [String: String], image: FyydUploadImage, boundary: String) -> Data {
        var body = Data()

        for key in params.keys.sorted() {
            guard let value = params[key] else {
                continue
            }

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(image.filename)\"\r\n")
        body.append("Content-Type: \(image.mimeType)\r\n\r\n")
        body.append(image.data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        return body
    }

    private func userParameters(userID: Int? = nil, nick: String? = nil) -> [String: String?]? {
        if let userID {
            return ["user_id": "\(userID)"]
        }

        if let nick, !nick.isEmpty {
            return ["nick": nick]
        }

        print("fyyd request skipped: either userID or nick must be provided.")
        return nil
    }

    private func podcastParameters(podcastID: Int? = nil, podcastSlug: String? = nil) -> [String: String?]? {
        if let podcastID {
            return ["podcast_id": "\(podcastID)"]
        }

        if let podcastSlug, !podcastSlug.isEmpty {
            return ["podcast_slug": podcastSlug]
        }

        print("fyyd request skipped: either podcastID or podcastSlug must be provided.")
        return nil
    }

    private func categoryParameters(categoryID: Int? = nil, categorySlug: String? = nil) -> [String: String?]? {
        if let categoryID {
            return ["category_id": "\(categoryID)"]
        }

        if let categorySlug, !categorySlug.isEmpty {
            return ["category_slug": categorySlug]
        }

        print("fyyd request skipped: either categoryID or categorySlug must be provided.")
        return nil
    }

    private func boolParameter(_ value: Bool?) -> String? {
        value.map { $0 ? "1" : "0" }
    }

    private func jsonArrayString(from values: [Int]?) -> String? {
        guard let values else {
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: values),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func fragmentParameters(from fragment: String?) -> [String: String] {
        guard let fragment, !fragment.isEmpty else {
            return [:]
        }

        var values: [String: String] = [:]

        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard let rawKey = parts.first else {
                continue
            }

            let key = String(rawKey).removingPercentEncoding ?? String(rawKey)
            let value = parts.count > 1
                ? (String(parts[1]).removingPercentEncoding ?? String(parts[1]))
                : ""
            values[key] = value
        }

        return values
    }

    private func log(_ error: Error, endpoint: String) {
        print("fyyd request failed for \(endpoint): \(error)")
    }
}

@available(iOS 16, macOS 12, *)
public typealias FyydClient = FyydSearchManager

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }

        append(data)
    }
}
