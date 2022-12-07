

import Foundation
import SwiftyJSON

open class TMDBApi {
    
    /// Creates new instance of TMDBManager class
    public static let shared = TMDBApi()
    
    let client = HttpClient(config: .init(serverURL: TMDB.base))
    
    /**
     Load movie posters from TMDB.
     
     - Parameter forMediaOfType:    The type of the media, either movie or show.
     - Parameter TMDBId:        The tmdb id of the media.
     
     - Parameter completion:        The completion handler for the request containing a poster, backdrop url and an optional error.
     */
    open func getPoster(forMediaOfType type: TMDB.MediaType, TMDBId tmdb: Int) async -> (backdrop: String, poster: String) {
        var image: String?
        var backdrop: String?
        
        let path = "/" + type.rawValue + "/\(tmdb)" + TMDB.images
        if let response = try? await client.request(.get, path: path, parameters: TMDB.defaultHeaders).responseData() {
            let responseDict = JSON(response)
            if let poster = responseDict["posters"].first?.1["file_path"].string {
                image = "https://image.tmdb.org/t/p/w780" + poster
            }
            if let backdrops = responseDict["backdrops"].first?.1["file_path"].string {
                backdrop = "https://image.tmdb.org/t/p/w1280" + backdrops
            }
        }
        return (backdrop: backdrop ?? "", poster: image ?? "")
    }
    
    /**
     Load season posters from TMDB. Either a tmdb id or an imdb id must be passed in.
     
     - Parameter tmdbId:          The tmdb id of the show.
     - Parameter season:            The season of the show.
     */
    open func getSeasonPoster(tmdbId: Int, season: Int) async throws -> String {
        let path = TMDB.tv + "/\(tmdbId)" + TMDB.season + "/\(season)" + TMDB.images
        let data = try await client.request(.get, path: path, parameters: TMDB.defaultHeaders).responseData()
        let responseDict = JSON(data)
        var image: String?
        if let poster = responseDict["posters"].first?.1["file_path"].string {
            image = "https://image.tmdb.org/t/p/w500" + poster
        }

        return image ?? ""
    }
    
    /**
     Load episode screenshots from TMDB. Either a tmdb id or an imdb id must be passed in.
     - Parameter tmdbId:          The tmdb id of the show.
     - Parameter season:            The season number of the episode.
     - Parameter episode:           The episode number of the episode.
     */
    open func getEpisodeScreenshots(tmdbId: Int, season: Int, episode: Int) async throws -> String {
        let path = TMDB.tv + "/\(tmdbId)" + TMDB.season + "/\(season)" + TMDB.episode + "/\(episode)" + TMDB.images
        let data = try await client.request(.get, path: path, parameters: TMDB.defaultHeaders).responseData()
        let responseDict = JSON(data)

        var image: String?
        if let screenshot = responseDict["stills"].first?.1["file_path"].string {
            image = "https://image.tmdb.org/t/p/w1280" + screenshot
        }
        return image ?? ""
    }
    
    /**
     Load character headshots from TMDB.
     
     - Parameter tmdbId:              The tmdb id of the person.
     */
    open func getCharacterHeadshots(tmdbId: Int) async throws -> String {
        let path = TMDB.person + "/\(tmdbId)" + TMDB.images
        let data = try await client.request(.get, path: path, parameters: TMDB.defaultHeaders).responseData()
        let responseDict = JSON(data)
        
        var image: String?
        if let headshot = responseDict["profiles"].first?.1["file_path"].string {
            image = "https://image.tmdb.org/t/p/w780" + headshot
        }
        return image ?? ""
    }
    
    /**
     Load trailer video from TMDB.
     
     - Parameter tmdbId:          The tmdb id of the show.
     - Parameter season:            The season number of the episode.
     */
    open func getTrailerVideo(tmdbId: Int, season: Int) async throws -> String? {
        let path = TMDB.tv + "/\(tmdbId)" + TMDB.season + "/\(season)" + TMDB.videos
        let data = try await client.request(.get, path: path, parameters: TMDB.defaultHeaders).responseData()
        let responseDict = JSON(data)
        print(responseDict.rawValue)
        
        var trailerId: String?
        if let item = responseDict["results"].array?.first(where: { item in
            return item["site"].string == "YouTube" && item["type"].string == "Trailer"
        }) {
            trailerId = item["key"].string
        }
        
        if trailerId == nil, let item = responseDict["results"].array?.first(where: { item in
            return item["site"].string == "YouTube" && item["type"].string == "Teaser"      
        }) {
            trailerId = item["key"].string
        }
        
        if trailerId == nil, let item = responseDict["results"].array?.first(where: { item in
            return item["site"].string == "YouTube"
        }) {
            trailerId = item["key"].string
        }
        
        return trailerId
    }
} 
