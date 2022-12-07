//
//  LoadExternalTorrentViewModel.swift
//  PopcornTime (tvOS)
//
//  Created by Alexandru Tudose on 19.09.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation
import GCDWebServer
import PopcornKit

class LoadExternalTorrentViewModel: ObservableObject {
    var webserver = GCDWebServer()
    
    @Published var playTorrent: PlayTorrent?
    struct PlayTorrent: Identifiable & Equatable {
        var id: String { movie.id }
        var torrent: Torrent
        var movie: Movie
    }
    @Published var displayUrl = ""
    
    init() {
        configureServer()
    }
    
    func startServer() {
        webserver.start(withPort: 54320, bonjourName: "popcorn")
        displayUrl = webserver.serverURL?.absoluteString ?? ""
    }
    
    func stopServer() {
        webserver.stop()
    }
    
    let serveDirectory = Bundle.main.path(forResource: "torrent_upload", ofType: "")!
    let indexFilename = "index.html"
    fileprivate func configureServer() {
        // serve the website located in Supporting Files/torrent_upload when we receive a GET request for /
        webserver.addGETHandler(forBasePath: "/", directoryPath: serveDirectory, indexFilename: indexFilename, cacheAge: 3600, allowRangeRequests: false)
        
        webserver.addHandler(forMethod: "GET", path: "/torrent", request: GCDWebServerRequest.self, processBlock: { request in
            
            // get magnet link that is inserted as a link tag from the website
            let magnetLink = request.query?["link"]!.removingPercentEncoding ?? ""
            
            // start to stream the new movie asynchronously as we do not want to mess the web server response
            DispatchQueue.main.async {
                let torrent = Torrent(url: magnetLink)
                let title = self.titleFromUrl(magnetLink: magnetLink)
                let movie = Movie(title: title, id: magnetLink, torrents: [torrent])
                self.playTorrent = PlayTorrent(torrent: torrent, movie: movie)
            }
            
            return GCDWebServerDataResponse(statusCode:200)
        })
    }
    
    func titleFromUrl(magnetLink: String) -> String {
        var title = magnetLink
        if let startIndex = title.range(of: "dn="){
            title = String(title[startIndex.upperBound...])
            if title.contains("&tr") {
                title = String(title[title.startIndex ... title.range(of: "&tr")!.lowerBound])
            }
        }
        return title
    }
}
