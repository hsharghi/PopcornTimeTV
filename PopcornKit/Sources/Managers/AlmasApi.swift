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
    
    public func getMovieLinks(imdbUrl: URL) async throws -> [DownloadLink] {
        let imdbId = imdbUrl.lastPathComponent
        guard imdbId.hasPrefix("tt") else { return [] }
        let data = try await client.request(.get, path: "/", parameters: ["showitem":imdbId]).responseData()
        guard let html = String(data: data, encoding: .utf8) else { return [] }

        let links = try findLinks(from: html)
        
        return links
        
    }
    
    private func findLinks(from html: String) throws -> [DownloadLink] {
        let doc = try SwiftSoup.parse(html)
        let div = try doc.select("div.movieLinks").first()
        let linksElement = div?.children()
        var links = [DownloadLink]()
        for p in linksElement?.array() ?? [] {
            let a = try p.select("a")
            let text = try a.text()
            let link = try a.attr("href")
//            link = link.removingPercentEncoding ?? link
            let parts = text.components(separatedBy: "/")
            guard parts.count >= 3 else { continue }
            let quality = parts.first!.trimmingCharacters(in: .whitespaces)
            let size = parts.last!.trimmingCharacters(in: .whitespaces)
            let encoder = text
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: quality, with: "")
                .replacingOccurrences(of: size, with: "")
                .trimmingCharacters(in: .whitespaces)
            let format = link.components(separatedBy: ".").last?.uppercased() ?? ""
            let downloadLink = DownloadLink(title: quality, encoder: encoder, size: size, format: format, link: link)
            links.append(downloadLink)
        }
        return links
    }
}

