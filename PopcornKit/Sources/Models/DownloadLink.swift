//
//  File.swift
//  
//
//  Created by Hadi Sharghi on 2024-03-26.
//

import Foundation


struct DownloadLink {
    let title: String
    let encoder: String
    let size: String
    let format: String
    let season: Int?
    let episode: Int?
    let link: String
    
    init(title: String, encoder: String, size: String, format: String, season: Int? = nil, episode: Int? = nil, link: String) {
        self.title = title
        self.encoder = encoder
        self.size = size
        self.format = format
        self.season = season
        self.episode = episode
        self.link = link
    }
}


extension DownloadLink {
    
    static let movieLinks: [DownloadLink] = [
        .init(title: "1080p 10bit WEB-DL x265 SoftSub", encoder: "YTS", size: "2.65 GB", format: "MKV", link: ""),
        .init(title: "720p WEB-DL SoftSub", encoder: "YTS", size: "1.15 MB", format: "MKV", link: ""),
        .init(title: "720p 10bit WEB-DL x265 SoftSub", encoder: "PSA", size: "968 MB", format: "MKV", link: ""),
        .init(title: "480p HardSub", encoder: "Ganool", size: "720 MB", format: "MKV", link: ""),
    ]
}
