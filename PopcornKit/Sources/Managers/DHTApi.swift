//
//  DHTApi.swift
//  
//
//  Created by Alexandru Tudose on 20.04.2024.
//

import Foundation

open class DHTApi {
    let client = HttpClient(config: HttpApiConfig(serverURL: DHT.base))
    
    public static let shared = DHTApi()
    
    
    public func loadEndpoints() async throws -> DHTPopcornURLs {
        return try await client.request(.get, path: "", parameters: [:]).responseDecode()
    }
}

// {"server":"https://fusme.link/,https://jfper.link/,https://uxert.link/,https://yrkde.link/","git":"https://github.com/popcorn-official/popcorn-desktop/","site":"https://popcorn-time.site/","r":"PopcornTimeApp","v":"0.5.0","keys":{"os":"Butter","fanart":"ce4bba4b3cc473306c6cddb4e1cb0da4","tvdb":"80A769280C71D83B","tmdb":"ac92176abc89a80e6f5df9510e326601","trakttv":{"id":"647c69e4ed1ad13393bf6edd9d8f9fb6fe9faf405b44320a6b71ab960b4540a2","s":"f55b0a53c63af683588b47f6de94226b7572a6f83f40bd44c58a7c83fe1f2cb1"}}}
public struct DHTPopcornURLs: Codable {
    public var server: String
    
}
