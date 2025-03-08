//
//  File.swift
//
//
//  Created by Alexandru Tudose on 18.12.2021.
//

import Foundation
import SwiftyJSON
import SwiftSoup
import RegexBuilder

open class AlmasApi: NSObject {
    /// Creates new instance of AlmasApi class
    public static let shared = AlmasApi()
    
    let client = HttpClient(config: .init(serverURL: Almas.base))
    
    public func getMovieLinks(imdbId: String) async throws -> [DownloadLink] {
        guard imdbId.hasPrefix("tt") else { return [] }
        do {
            let data = try await client.request(.get, path: "/", parameters: ["showitem":imdbId]).responseData()
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            
            let links = try findLinks(from: html)
            
            return links
        } catch {
            print(error.localizedDescription)
            return []
        }
        
    }
    
    public func getShowLink(imdbId: String, season: Int? = nil) async throws -> [DownloadLink] {
        let seasons = try await getSeasons(imdbId: imdbId)
        var filteredSeasons = seasons
        if let season {
            filteredSeasons = seasons.filter { $0.key == season }
        }
        var allLinks = [DownloadLink]()

//        filteredSeasons = [1: ["https://nairobi.almasnewerstorage.ir/Series/H/Halo/S01/1080p%20WEBRip%206CH%20x265%2010bit%20PSA/"]]
        try await withThrowingTaskGroup(of: [DownloadLink].self) { group in
            for filteredSeason in filteredSeasons {
                for link in filteredSeason.value {
                    group.addTask { [weak self] in
                        try await self?.findSeasonLink(url: link) ?? []
                    }
                }
            }
            for try await result in group {
                allLinks.append(contentsOf: result)
            }
        }
        return allLinks
    }
    
    public func getSeasons(imdbId: String) async throws -> [Int: [String]] {
        guard imdbId.hasPrefix("tt") else { return [:] }
        let data = try await client.request(.get, path: "/", parameters: ["showitem":imdbId]).responseData()
        guard let html = String(data: data, encoding: .utf8) else { return [:] }
        do {
            let seasons = try findSeasons(from: html)
            return seasons
        } catch {
            return [:]
        }
    }
    
    private func findSeasonLink(url: String) async throws -> [DownloadLink] {
        var downloadLinks = [DownloadLink]()
        do {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

            let (data, _) = try await session.data(from: URL(string: url)!)
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            let doc = try SwiftSoup.parse(html)
            var rows = try doc.select("tr").array()
            guard rows.count >= 2 else { return [] }
            rows.removeFirst()
            rows.removeFirst()
            for row in rows {
                if let text = try row.select("td.n>a").first?.attr("href") {
                    let matches = findMatches(in: text)
                    guard !matches.isEmpty else { continue }
                    var encoderParts = matches[4].components(separatedBy: ".")
                    if encoderParts.count < 2 {
                        encoderParts = matches[4].components(separatedBy: "-")
                    }
                    if encoderParts.count < 2 {
                        encoderParts = matches[4].components(separatedBy: "_")
                    }
                    if encoderParts.count < 2 {
                        encoderParts = matches[4].components(separatedBy: " ")
                    }
                    let encoder = encoderParts.last ?? ""
                    let quality = matches[3]
                    var title = matches[4].replacingOccurrences(of: encoder, with: "")
                    if title.last == "." { title.removeLast() }
                    if title.first == "." { title.removeFirst() }
                    let season = Int(matches[1])
                    let episode = Int(matches[2])
                    let format = matches[5].uppercased()
                    var size = ""
                    if let sizeString = try row.select("td.s").first()?.text() {
                        size = sizeString + "B"
                    }
                    let link = "\(url.deletingSuffix("/"))/\(text)"
                    let downloadLink = DownloadLink(title: title, encoder: encoder, quality: quality, size: size, format: format, season: season, episode: episode, link: link)
                    downloadLinks.append(downloadLink)
                }
            }
        } catch {
            
        }

        return downloadLinks
    }
    
    private func findMatches(in string: String) -> [String] {
//        var matches = string.capturedGroups(withRegex: "^(.*?)\\.S(\\d{2})E(\\d{2})\\.(.*p)\\.(.*?)\\.(\\w+)$")
//        if matches.count >= 6 { 
//            var result = matches
//            result.removeFirst()
//            return result
//        }
//        matches = string.capturedGroups(withRegex: "^(.*?)\\_S(\\d{2})E(\\d{2})\\_(.*p)\\_(.*?)\\.(\\w+)$")
//        if matches.count >= 6 {
//            var result = matches
//            result.removeFirst()
//            return result
//        }
        if let (title, season, episode) = getTitleEpisodeAndSeason(from: string) {
            let quality = getQuality(from: string)
            let format = getFormat(from: string)
                .deletingPrefix(".")
            let encoder = string.replacingOccurrences(of: title, with: "")
                .replacingOccurrences(of: "S\(season)E\(episode)", with: "")
                .replacingOccurrences(of: quality, with: "")
                .replacingOccurrences(of: ".\(format)", with: "")
                .trimmingCharacters(in: .whitespaces)
                .deletingPrefix(".")
                .deletingPrefix("_")
                .deletingPrefix(" ")
                .deletingSuffix(".")
                .deletingSuffix("_")
                .deletingSuffix(" ")
            return [title, season, episode, quality, encoder, format]
        }
        return []
    }
    
    private func getTitleEpisodeAndSeason(from string: String) -> (String, String, String)? {
        let matches = string.capturedGroups(withRegex: "^(.*?)\\S(\\d{2})E(\\d{2})")
        if matches.count == 4 {
            return (matches[1], matches[2], matches[3])
        }
        return nil
    }
    
    private func getQuality(from string: String) -> String {
        let matches = string.capturedGroups(withRegex: "\\d{3,4}p")
        if matches.count >= 1 {
            return matches[0]
        }

        return ""
    }
    
    private func getFormat(from string: String) -> String {
        let matches = string.capturedGroups(withRegex: "\\.(\\w+)$")
        if matches.count >= 1 {
            return matches[0]
        }

        return ""
    }
    
    private func findSeasons(from html: String) throws -> [Int: [String]] {
        let doc = try SwiftSoup.parse(html)
        let links = try doc.select("a").array()
        var seasonsDictionary = [Int: [String]]()
        for link in links {
            let url = try link.attr("href")
            guard let seasonNumber = extractSeasonNumber(from: url) else { continue }
            var currentUrls = seasonsDictionary[seasonNumber] ?? []
            currentUrls.append(url)
            seasonsDictionary[seasonNumber] = currentUrls
        }
        return seasonsDictionary
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
            let title = parts.first!.trimmingCharacters(in: .whitespaces)
            let size = parts.last!.trimmingCharacters(in: .whitespaces)
            let quality = getQuality(from: text)
            let encoder = text
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: quality, with: "")
                .replacingOccurrences(of: size, with: "")
                .trimmingCharacters(in: .whitespaces)
            let format = link.components(separatedBy: ".").last?.uppercased() ?? ""
            let downloadLink = DownloadLink(title: title, encoder: encoder, quality: quality, size: size, format: format, link: link)
            links.append(downloadLink)
        }
        return links
    }
    
    func extractSeasonNumber(from url: String) -> Int? {
        let pattern = "/S(\\d{2})/"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: url, options: [], range: NSRange(location: 0, length: url.utf16.count))
            
            if let match = matches.first {
                let range = Range(match.range(at: 1), in: url)!
                let seasonNumber = url[range]
                return Int(String(seasonNumber))
            }
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
}


public extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 0 else { return results }

        for i in 0...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        return results
    }
    
        func deletingPrefix(_ prefix: String) -> String {
            guard self.hasPrefix(prefix) else { return self }
            return String(self.dropFirst(prefix.count))
        }
    
        func deletingSuffix(_ prefix: String) -> String {
            guard self.hasSuffix(prefix) else { return self }
            return String(self.dropLast(prefix.count))
        }

}

extension AlmasApi: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       //Trust the certificate even if not valid
       let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)

       completionHandler(.useCredential, urlCredential)
    }
}
