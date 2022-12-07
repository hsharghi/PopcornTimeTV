//
//  DownloadViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 25.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornTorrent
import MediaPlayer
import PopcornKit
import Combine

class DownloadViewModel: NSObject, ObservableObject {
    var download: PTTorrentDownload
    @Published var status: PTTorrentStatus
    var observation: NSKeyValueObservation?
    var downloadManager = PTTorrentDownloadManager.shared()
    var media: Media
    var torrent = Torrent() // No torrent metadata necessary, media
    let downloadDeleted = NSNotification.Name("DownloadDeleted")
    
    init(download: PTTorrentDownload) {
        self.download = download
        status = download.torrentStatus
        media = Movie(download.mediaMetadata) ?? Episode(download.mediaMetadata)!
    }
    
    func addObserver() {
        observation = download.observe(\.torrentStatus) { [weak self] download, change in
            self?.status = download.torrentStatus
        }
        status = download.torrentStatus
    }
    
    func delete() {
        switch download.downloadStatus {
        case .processing, .paused, .downloading, .failed:
            downloadManager.stop(download) // will also clear downloeded data
        case .finished:
            downloadManager.delete(download)
            NotificationCenter.default.post(name: downloadDeleted, object: self)
        @unknown default:
            break
        }
    }
    
    func continueDownload() {
        downloadManager.resumeDownload(download)
    }
    
    func pause() {
        downloadManager.pause(download)
        download.save()
    }
    
    var imageUrl: String {
        let episode = media as? Episode
        return episode?.show?.smallCoverImage ?? media.smallCoverImage ?? ""
    }
    
    var placeholderImage: String {
        return media is Episode ? "Episode Placeholder" : "Movie Placeholder"
    }
    
    var title: String {
        if let episode = media as? Episode {
            return "\(episode.episode). " + episode.title
        } else {
            return media.title
        }
    }
    
    var detailText: String {
        switch download.downloadStatus {
        case .processing, .downloading:
            return downloadingDetailText
        case .paused:
            return "Paused".localized
        case .finished:
            return download.fileSize.stringValue
        case .failed:
            return "Download Failed".localized
        @unknown default:
            return "N/A"
        }
    }
    
    var downloadingDetailText: String {
        let speed: String
        let downloadSpeed = TimeInterval(download.torrentStatus.downloadSpeed)
        let sizeLeftToDownload = TimeInterval(download.fileSize.longLongValue - download.totalDownloaded.longLongValue)
        
        if downloadSpeed > 0 {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.includesTimeRemainingPhrase = true
            formatter.includesApproximationPhrase = true
            formatter.allowedUnits = [.hour, .minute]
            
            let remainingTime = sizeLeftToDownload/downloadSpeed
            if remainingTime < 60 { // seconds
                formatter.allowedUnits = [.second]
            }
            
            if let formattedTime = formatter.string(from: remainingTime) {
                speed = " • " + formattedTime
            } else {
                speed = ""
            }
        } else {
            speed = ""
        }
        
        return ByteCountFormatter.string(fromByteCount: Int64(download.torrentStatus.downloadSpeed), countStyle: .binary) + "/s" + speed
    }
    
    var watched: Bool {
        if let _ = media as? Episode {
            return WatchedlistManager<Episode>.episode.isAdded(media.id)
        } else {
            return WatchedlistManager<Movie>.movie.isAdded(media.id)
        }
    }
}


extension PTTorrentDownload {
    
    static func dummy(status: PTTorrentDownloadStatus) -> PTTorrentDownload {
        return PTTorrentDownload(mediaMetadata: Movie.dummy().mediaItemDictionary, downloadStatus: status)
    }
    
    static func dummyEpisode(status: PTTorrentDownloadStatus) -> PTTorrentDownload {
        let episode = Episode(JSON: showEpisodesJSON[0])!
        return PTTorrentDownload(mediaMetadata: episode.mediaItemDictionary, downloadStatus: status)
    }
}
