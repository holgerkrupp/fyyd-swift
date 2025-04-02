//
//  FyydSearchManager.swift
//  PodcastClient
//
//  Created by Holger Krupp on 06.02.24.
//

import Foundation

@available(iOS 16.0, *)
class FyydSearchManager{
    
    enum Endpoints{
        case podcasts, episode, hot
        
        var url:URL? {
            switch self {
            case .podcasts:
                return URL(string: "https://api.fyyd.de/0.2/search/podcast")
            case .episode:
                return URL(string: "https://api.fyyd.de/0.2/search/episode")
            case .hot:
                return URL(string: "https://api.fyyd.de/0.2/feature/podcast/hot")

            }
        }
        
    }
    
    func getLanguages() async -> [String]?{
    
        if let requestURL = URL(string: "https://api.fyyd.de/0.2/feature/podcast/hot/languages"){
            var components = URLComponents()
            components.scheme = requestURL.scheme
            components.host = requestURL.host
            components.path = requestURL.path()
    
            var request = URLRequest(url: components.url ?? requestURL)
            
            let session = URLSession.shared
            
            do {
                let (responseData, _) = try await session.data(for: request)
                
                
                guard let json = try JSONSerialization.jsonObject(with: responseData , options: []) as? [String: Any] else {
                    // appropriate error handling
                    return nil
                }
                
                
                if let lanuages = json["data"] as? [String]{
                    return lanuages
                }
            }catch{
                print(error)
                
            }
        }
        return nil
        
    }
    
    func search(for term: String, endpoint: Endpoints = .podcasts, lang: String? = nil, count: Int? = 10) async -> [Podcast]? {
        guard !term.isEmpty, let requestURL = endpoint.url else { return nil }

        var components = URLComponents()
        components.scheme = requestURL.scheme
        components.host = requestURL.host
        components.path = requestURL.path()
        components.queryItems = [URLQueryItem(name: "title", value: term)]

        if let lang = lang {
            components.queryItems?.append(URLQueryItem(name: "language", value: lang))
        }
        
        if let count = count {
            components.queryItems?.append(URLQueryItem(name: "count", value: "\(count)"))
        }

        guard let url = components.url else { return nil }

        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let response = try decoder.decode(PodcastAPIResponse.self, from: responseData)
            return response.data
        } catch {
            print("Error fetching podcasts: \(error)")
            return nil
        }
    }

    
    
}
struct PodcastAPIResponse: Codable {
    let status: Int
    let msg: String
    let meta: Meta
    let data: [Podcast]
}

struct Meta: Codable {
    let paging: Paging
    let apiInfo: APIInfo
    
    enum CodingKeys: String, CodingKey {
        case paging
        case apiInfo = "API_INFO"
    }
}

struct Paging: Codable {
    let count, page, firstPage, lastPage: Int
    let nextPage: Int?
    let prevPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case count, page
        case firstPage = "first_page"
        case lastPage = "last_page"
        case nextPage = "next_page"
        case prevPage = "prev_page"
    }
}

struct APIInfo: Codable {
    let apiVersion: Double
    
    enum CodingKeys: String, CodingKey {
        case apiVersion = "API_VERSION"
    }
}


struct Podcast: Codable {
    let title: String
    let id: Int
    let xmlURL, htmlURL, imgURL: String
    let status: Int
    let slug: String
    let layoutImageURL, thumbImageURL, microImageURL: String
    let language: String
    let lastPoll: String
    let generator: String
    let categories: [Int]
    let lastPub: String
    let rank: Int
    let urlFyyd: String
    let description: String
    let subtitle: String
    let episodes: [Episode]
    
    enum CodingKeys: String, CodingKey {
        case title, id, status, slug, language, generator, categories, rank, episodes
        case xmlURL = "xmlURL"
        case htmlURL = "htmlURL"
        case imgURL = "imgURL"
        case layoutImageURL = "layoutImageURL"
        case thumbImageURL = "thumbImageURL"
        case microImageURL = "microImageURL"
        case lastPoll = "lastpoll"
        case lastPub = "lastpub"
        case urlFyyd = "url_fyyd"
        case description, subtitle
    }
}

struct Episode: Codable {
    let title: String
    let id: Int
    let guid: String
    let url: String
    let enclosure: String
    let podcastID: Int
    let imgURL: String
    let pubDate: String
    let duration: Int
    let urlFyyd: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case title, id, guid, url, enclosure, duration, description
        case podcastID = "podcast_id"
        case imgURL = "imgURL"
        case pubDate = "pubdate"
        case urlFyyd = "url_fyyd"
    }
}
