//
//  File.swift
//
//
//  Created by Alexandru Tudose on 18.12.2021.
//

import Foundation
import SwiftyJSON
import SwiftSoup

open class AlmasApi {
    /// Creates new instance of AlmasApi class
    public static let shared = AlmasApi()
    
    let client = HttpClient(config: .init(serverURL: Almas.base))
    
    func getMovieLinks(imdbId: String) async throws -> [DownloadLink] {
        let path = Almas.base + "\(imdbId)"
        let data = try await client.request(.get, path: path).responseData()
        guard let html = String(data: data, encoding: .utf8) else { return [] }

        let links = try findLlinks(from: html)
        
        return links
        
    }
    
    private func findLlinks(from html: String) throws -> [DownloadLink] {
        let doc = try SwiftSoup.parse(html)
        let div = try doc.select("div.movieLinks").first()
        let linksElement = div?.children()
        var links = [DownloadLink]()
        for p in linksElement?.array() ?? [] {
            let a = try p.select("a")
            let text = try a.val()
            let link = try a.attr("href")
            let parts = text.components(separatedBy: "/")
            guard parts.count == 3 else { return [] }
            let quality = parts[0]
            let encoder = parts[1]
            let size = parts[2]
            let format = link.components(separatedBy: ".").last?.uppercased() ?? ""
            let downloadLink = DownloadLink(title: quality, encoder: encoder, size: size, format: format, link: link)
            links.append(downloadLink)
        }
        return links
    }
}

