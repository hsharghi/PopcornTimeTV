//
//  File.swift
//  
//
//  Created by Hadi Sharghi on 2024-03-26.
//

import Foundation


public struct DownloadLink {
    public let title: String
    public let encoder: String
    public let size: String
    public let format: String
    public let season: Int?
    public let episode: Int?
    public let link: String
    
    public init(title: String, encoder: String, size: String, format: String, season: Int? = nil, episode: Int? = nil, link: String) {
        self.title = title
        self.encoder = encoder
        self.size = size
        self.format = format
        self.season = season
        self.episode = episode
        self.link = link
    }
    
    public var encodedUrl: String? {
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "~-_."))
        return self.link.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}

extension DownloadLink: Equatable, Comparable, Identifiable {
    
    public var id: String {
        self.title + self.size
    }
    
    var actualSize: Double {
        let components = self.size.components(separatedBy: " ")
        guard components.count == 2,
        let bytes = Double(components[0]) else { return 0 }
        let multiplier = switch components[1] {
        case "KB": 1024
        case "MB": 1024 * 1024
        case "GB": 1024 * 1024 * 1024
        default: 1
        }
        return bytes * Double(multiplier)
    }
    
    public static func ==(lhs: DownloadLink, rhs: DownloadLink) -> Bool {
        return lhs.actualSize == rhs.actualSize
    }
    
    public static func < (lhs: DownloadLink, rhs: DownloadLink) -> Bool {
        return lhs.actualSize < rhs.actualSize
    }

}



public extension DownloadLink {
    
    static let movieLinks: [DownloadLink] = [
        .init(title: "1080p 10bit WEB-DL x265 SoftSub", encoder: "YTS", size: "2.65 GB", format: "MKV", link: ""),
        .init(title: "720p WEB-DL SoftSub", encoder: "YTS", size: "1.15 MB", format: "MKV", link: ""),
        .init(title: "720p 10bit WEB-DL x265 SoftSub", encoder: "PSA", size: "968 MB", format: "MKV", link: ""),
        .init(title: "480p HardSub", encoder: "Ganool", size: "720 MB", format: "MKV", link: ""),
    ]
}
