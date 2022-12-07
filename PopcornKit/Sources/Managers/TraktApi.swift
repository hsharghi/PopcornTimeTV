

import ObjectMapper
import SwiftyJSON
import Foundation

open class TraktApi {

    /// Creates new instance of TraktManager class
    public static let shared = TraktApi()
    
    /// OAuth state parameter added for extra security against cross site forgery.
    fileprivate var state: String!
    
    let client = HttpClient(config: .init(serverURL: Trakt.base, configuration: {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForResource = 30
//        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpAdditionalHeaders = Trakt.Headers.Default
        return configuration
    }()))
    
    func traktCredentials() async throws -> OAuthCredential {
        return try await TraktSession.shared.traktCredentials()
    }
    
    /**
     Scrobbles current video.
     
     - Parameter id:            The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter type:          The type of the item, either `Episode` or `Movie`.
     - Parameter status:        The status of the item.
     
     */
    open func scrobble(_ id: String, progress: Float, type: Trakt.MediaType, status: Trakt.WatchedStatus) async throws {
        let credential = try await traktCredentials()
        
        guard progress != 0 else {
            return try await removePlaybackProgress(id, type: type)
        }
        
        let parameters: [String: Any]
        if type == .movies {
            parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
        } else {
            parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
        }
        
        let path = Trakt.scrobble + "/\(status.rawValue)"
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        return try await client.request(.post, path: path, parameters: parameters, headers: headers).response()
    }
    
    /**
     Load episode metadata from API.
     
     - Parameter show:          The imdbId or slug for the show.
     - Parameter episodeNumber: The number of the episode in relation to its current season.
     - Parameter seasonNumber:  The season of which the episode is in.
     */
    open func getEpisodeMetadata(_ showId: String, episodeNumber: Int, seasonNumber: Int) async throws -> Episode {
        let path = Trakt.shows + "/\(showId)" + Trakt.seasons + "/\(seasonNumber)" + Trakt.episodes + "/\(episodeNumber)"
        return try await client.request(.get, path: path, parameters: Trakt.extended).responseMapable(context: TraktContext())
    }
    
    /**
     Retrieves users previously watched videos.
     
     - Parameter type:          The type of the item (either movie or episode).
    
     */
    open func getWatched<T: Media>(forMediaOfType type: T.Type) async throws -> [T] {
        let credential = try await traktCredentials()
        
        let type = type is Movie.Type ? Trakt.movies : Trakt.episodes
        
        let path = Trakt.sync + Trakt.history + type
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        let data = try await client.request(.get, path: path, parameters: ["extended": "full", "limit": Int.max], headers: headers).responseData()
        let responseObject = JSON(data)
        var watchedlist = [T]()
        
        for (_, item) in responseObject {
            guard let type = item["type"].string, let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject) else { continue
            }
            guard var episode = media as? Episode, let show = Mapper<Show>(context: TraktContext()).map(JSONObject: item["show"].dictionaryObject) else {
                watchedlist.append(media)
                continue
            }
            episode.show = show
            watchedlist.append(episode as! T)
        }
        return watchedlist
    }
    
    /**
     Retrieves users playback progress of video if applicable.
     
     - Parameter type: The type of the item (either movie or episode).
     
     - Parameter completion: The completion handler for the request containing a dictionary of either imdbIds or tvdbIds depending on the type selected as keys and the users corrisponding watched progress as values and an optional error. Eg. ["tt1431045": 0.5] means you have watched half of Deadpool.
     */
    open func getPlaybackProgress<T: Media>(forMediaOfType type: T.Type) async throws -> [String: Float] {
        let credential = try await traktCredentials()
        
        let mediaType: String
        switch type {
        case is Movie.Type:
            mediaType = Trakt.movies
        case is Episode.Type:
            mediaType = Trakt.episodes
        default:
            fatalError("Only retrieving progress for movies and episode is supported.")
        }

        let headers = Trakt.Headers.Authorization(credential.accessToken)
        let path = Trakt.sync + Trakt.playback + mediaType
        let data = try await client.request(.get, path: path, parameters: Trakt.extended, headers: headers).responseData()
        
        let responseObject = JSON(data)
        var progressDict = [String: Float]()
        
        for (_, item) in responseObject {
            guard let type = item["type"].string,
                let progress = item["progress"].float,
                progress != 0,
                let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject)
                else { continue }

            progressDict[media.id] = progress/100.0
        }
        return progressDict
    }
    
    /**
     `Nil`s a users playback progress of a specified media. If `id` is invalid, 404 error will be thrown.
     
     - Parameter id: The imdbId of the movie or tvdbId of the episode.

     */
    open func removePlaybackProgress(_ id: String, type: Trakt.MediaType) async throws {
        let credential = try await traktCredentials()
        
        let path = Trakt.sync + Trakt.playback + "/\(type.rawValue)"
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        let data = try await client.request(.get, path: path, headers: headers).responseData()
        let responseObject = JSON(data)
                
        var playbackId: Int?
                
        for (_, item) in responseObject {
            guard let t = item["type"].string,
                let playback = item["id"].int
                else { continue }
            let ids = item[t]["ids"]
            if (type == .movies && id == ids["imdb"].string) || (type == .episodes && Int(id) == ids["tvdb"].int) {
                playbackId = playback
                break
            }
        }
                
        guard let id = playbackId else {
            return
        }
                
        try await client.request(.delete, path: Trakt.sync + Trakt.playback + "/\(id)", headers: headers).response()
    }
    
    /**
     Removes a movie or episode from a users watched history.
     
     - Parameter id:    The imdbId or tvdbId of the movie, episode or show.
     - Parameter type:  The type of the item (movie or episode).
     
     */
    open func remove(_ id: String, fromWatchedlistOfType type: Trakt.MediaType) async throws {
        let credential = try await traktCredentials()
        
        let parameters: [String: Any]
        if type == .movies {
            parameters = ["movies": [["ids": ["imdb": id]]]]
        } else if type == .episodes {
            parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
        } else {
            parameters = [:]
        }
        
        let path = Trakt.sync + Trakt.history + Trakt.remove
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        try await client.request(.post, path: path, parameters: parameters, headers: headers).response()
    }
    
    /**
     Adds specified media to users watch history.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     */
    open func add(_ id: String, toWatchedlistOfType type: Trakt.MediaType) async throws {
        let credential = try await traktCredentials()
        
        let parameters: [String: Any]
        if type == .movies {
            parameters = ["movies": [["ids": ["imdb": id]]]]
        } else if type == .episodes {
            parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
        } else {
            parameters = [:]
        }
        
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        try await client.request(.post, path: Trakt.sync + Trakt.history, parameters: parameters, headers: headers).response()
    }
    
    /**
     Retrieves cast and crew information for a movie or show.
     
     - Parameter type:  The type of the item (movie or show).
     - Parameter id:    The id of the movie or show.
     */
    open func getPeople(forMediaOfType type: Trakt.MediaType, id: String) async throws -> (actors: [Actor], crew: [Crew]) {
        let path = "/\(type.rawValue)/\(id)" + Trakt.people
        let traktPeople: TracktPeople = try await client.request(.get, path: path).responseMapable()
        return (actors: traktPeople.actors, crew: traktPeople.crew)
    }
    
    /**
     Retrieves users watchlist.
     
     - Parameter type: The type struct of the item eg. `Movie` or `Show`. Episodes not supported
     
     */
    open func getWatchlist<T: Media>(forMediaOfType type: T.Type) async throws -> [T] {
        let credential = try await traktCredentials()
        
        let mediaType: String
        switch type {
        case is Movie.Type:
            mediaType = Trakt.movies
        case is Show.Type:
            mediaType = Trakt.shows
        default:
            mediaType = ""
        }
        
        let path = Trakt.sync + Trakt.watchlist + mediaType
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        let data = try await client.request(.get, path: path, parameters: Trakt.extended, headers: headers).responseData()
        let responseObject = JSON(data)
        var watchlist = [T]()
        
        for (_, item) in responseObject {
            guard let type = item["type"].string, let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject) else {
                continue
            }
            watchlist.append(media)
        }
        return watchlist
    }
    
    /**
     Adds specified media to users watchlist.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     */
    open func add(_ id: String, toWatchlistOfType type: Trakt.MediaType) async throws {
        let credential = try await traktCredentials()
        
        let parameters: [String: Any]
        if type == .episodes {
            parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
        } else {
            parameters = [type.rawValue: [["ids": ["imdb": id]]]]
        }
        
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        try await client.request(.post, path: Trakt.sync + Trakt.watchlist, parameters: parameters, headers: headers).response()
    }
    
    /**
     Removes specified media from users watchlist.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     */
    open func remove(_ id: String, fromWatchlistOfType type: Trakt.MediaType) async throws {
        let credential = try await traktCredentials()
        
        let parameters: [String: Any]
        if type == .episodes {
            parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
        } else {
            parameters = [type.rawValue: [["ids": ["imdb": id]]]]
        }
        
        let path = Trakt.sync + Trakt.watchlist + Trakt.remove
        let headers = Trakt.Headers.Authorization(credential.accessToken)
        try await client.request(.post, path: path, parameters: parameters, headers: headers).response()
    }
    
    /**
     Retrieves related media.
     
     - Parameter media: The media you would like to get more information about. **Please note:** only the imdbdId is used but an object needs to be passed in for Swift generics to work so creating a blank object with only an imdbId variable initialised will suffice if necessary.
     */
    open func getRelated<T: Media>(_ media: T) async throws -> [T] {
        let path = (media is Movie ? Trakt.movies : Trakt.shows) + "/\(media.id)" + Trakt.related
        let items: [T] = try await client.request(.get, path: path, parameters: Trakt.extended).responseMapable(context: TraktContext())
        
        return items.filter({ $0.tmdbId != nil })
    }
    
    
    /**
     Retrieves movies or shows that the person in cast/crew in.
     
     - Parameter id:    The id of the person you would like to get more information about.
     - Parameter type:  Just the type of the media is required for Swift generics to work.
     */
    open func getMediaCredits<T: Media>(forPersonWithId id: String, mediaType type: T.Type) async throws -> [T] {
        var typeString = (type is Movie.Type ? Trakt.movies : Trakt.shows)
        let path = Trakt.people + "/\(id)" + typeString

        typeString.removeLast() // Removes 's' from the type string
        typeString.removeFirst() // Removes '/' from the type string
        
        let mediaCredit: TracktMediaCredits<T> = try await client.request(.get, path: path, parameters: Trakt.extended)
            .responseMapable(context: TraktContext(type: typeString))
        
        return mediaCredit.medias.filter({ $0.tmdbId != nil })
    }
    
    /// Downloads users latest watchlist and watchedlist from Trakt.
    open func syncUserData() {
        Task {
            _ = try? await WatchlistManager<Movie>.movie.refreshWatchlist()
            _ = try? await WatchlistManager<Show>.show.refreshWatchlist()
            
            _ = try? await WatchedlistManager<Movie>.movie.refreshProgress()
            _ = try? await WatchedlistManager<Movie>.movie.refreshWatched()
            _ = try? await WatchedlistManager<Episode>.episode.refreshProgress()
            _ = try? await WatchedlistManager<Episode>.episode.refreshWatched()
        }
    }
    
    open func refreshWatchlist() async throws {
        _ = try await WatchlistManager<Movie>.movie.refreshWatchlist()
        _ = try await WatchlistManager<Show>.show.refreshWatchlist()
    }
    
    /**
     Requests tmdb id for object with imdb id.
     
     - Parameter id:            Imdb id of object.
     */
    open func getTMDBId(forImdbId id: String) async throws -> Int {
        let path = Trakt.search + Trakt.imdb + "/\(id)"
        let data = try await client.request(.get, path: path).responseData()
        let responseObject = JSON(data).arrayValue.first
        guard let type = responseObject?["type"].string, let id = responseObject?[type]["ids"]["tmdb"].int else {
            throw APIError(type: .couldNotDecodeResponse)
        }
        return id
    }
    
//    /**
//     Requests episode info from tvdb.
//     
//     - Parameter id:            The tvdb identification code of the episode.
//     
//     - Parameter completion:    Completion handler for the request. Returns episode upon success, error upon failure.
//     */
//    open func getEpisodeInfo(forTvdb id: Int, completion: @escaping (Episode?, NSError?) -> Void) {
//        self.manager.request(Trakt.base + Trakt.search + Trakt.tvdb + "/\(id)", parameters:Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { (response) in
//            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
//            let responseObject = JSON(value)[0]
//            
//            var episode = Mapper<Episode>(context: TraktContext()).map(JSONObject: responseObject["episode"].dictionaryObject)
//            episode?.show = Mapper<Show>(context: TraktContext()).map(JSONObject: responseObject["show"].dictionaryObject)
//            
//            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: episode?.show?.id, orTMDBId: episode?.show?.tmdbId, season: episode?.season ?? -1, episode: episode?.episode ?? -1) { (tmdb, image, error) in
//                if let tmdb = tmdb { episode?.show?.tmdbId = tmdb }
//                if let image = image { episode?.largeBackgroundImage = image }
//                
//                completion(episode, error)
//            }
//        }
//    }
    
    /**
     Searches Trakt for people (crew or actor).
     
     - Parameter person:        The name of the person to search.
     */
    open func search(forPerson person: String) async throws -> [Person] {
        // Type of person doesn't matter as it will succeed either way.
        let persons: [Crew] = try await client.request(.get, path: Trakt.search + Trakt.person, parameters: ["query": person]).responseMapable()
        return persons
    }
}

/// When mapping to movies or shows from Trakt, the JSON is formatted differently to the Popcorn API. This struct is used to distinguish from which API the Media is being mapped from.
struct TraktContext: MapContext {
    var type: String = ""
}

struct TracktPeople: Mappable {
    var actors: [Actor]
    var crew: [Crew]
    
    private init(_ map: Map) throws {
        actors = []
        crew = []
        let responseObject = JSON(map.JSON)
        
        for (_, actor) in responseObject["cast"] {
            guard let actor = Mapper<Actor>().map(JSONObject: actor.dictionaryObject) else { continue }
            actors.append(actor)
        }
        for (role, people) in responseObject["crew"] {
            guard let people = Mapper<Crew>().mapArray(JSONObject: people.arrayObject) else { continue }
            for var person in people {
                person.roleType = Role(rawValue: role) ?? .unknown
                crew.append(person)
            }
        }
    }
    
    init?(map: Map) {
        self.actors = []
        self.crew = []
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let people = try? TracktPeople(map) {
                self = people
            }
        case .toJSON:
            abort()
        }
    }
}

struct TracktMediaCredits<T: Media>: Mappable {
    var medias: [T]
    
    private init(_ map: Map) throws {
        let context = map.context as! TraktContext
        medias = []
        
        let responseObject = JSON(map.JSON)
        for item in [responseObject["crew"], responseObject["cast"]].compactMap({ $0.array }) {
            for json in item {
                if let payload = json[context.type].dictionaryObject,
                   let mediaItem = Mapper<T>(context: TraktContext()).map(JSONObject: payload) {
                    medias.append(mediaItem)
                }
            }
        }
    }
    
    init?(map: Map) {
        self.medias = []
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let mediaCredits = try? TracktMediaCredits<T>(map) {
                self = mediaCredits
            }
        case .toJSON:
            abort()
        }
    }
}
