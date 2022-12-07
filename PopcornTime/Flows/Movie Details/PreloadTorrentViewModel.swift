//
//  PreloadTorrentViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 20.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation
import PopcornKit
import PopcornTorrent
import MediaPlayer.MPMediaItem
#if canImport(UIKit)
import UIKit
#endif

class PreloadTorrentViewModel: ObservableObject {
    var torrent: Torrent
    var media: Media
    var watchedProgress: Float = 0.0
    
    @Published var isProcessing = true
    @Published var progress: Float = 0.0
    @Published var speed: Int = 0
    @Published var seeds: Int = 0
    var streamer: PTTorrentStreamer?
    
    @Published var error: Error?
    @Published var showError = false
    @Published var showFileToPlay = false
    @Published var filesToPlay: [String] = []
    @Published var selectedFileToPlay: String?
    @Published var playerModel: PlayerViewModel?
    @Published var clearCache = ClearCache()
    
    var onReadyToPlay: (PlayerViewModel) -> Void
    
    init(torrent: Torrent, media: Media, onReadyToPlay: @escaping (PlayerViewModel) -> Void) {
        self.torrent = torrent
        self.media = media
        self.onReadyToPlay = onReadyToPlay
    }
    
    func cancel() {
        let isPlaying = playerModel != nil
        if !isPlaying {
            self.streamer?.cancelStreamingAndDeleteData(false)
        }
    }
    
    func playTorrent() {
        if let _ = media as? Movie {
            watchedProgress = WatchedlistManager<Movie>.movie.currentProgress(media.id)
        } else if let _ = media as? Episode {
            watchedProgress = WatchedlistManager<Episode>.episode.currentProgress(media.id)
        }
        
        #if os(iOS) || os(tvOS)
        UIApplication.shared.isIdleTimerDisabled = true
        let finishedLoading: () -> Void = {
            UIApplication.shared.isIdleTimerDisabled = false
//            let flag = UIDevice.current.userInterfaceIdiom != .tv
        }
        #else
        let finishedLoading: () -> Void = { }
        #endif
        
        self.play(fromFileOrMagnetLink: torrent.url, nextEpisodeInSeries: nil, finishedLoadingBlock: finishedLoading)
    }
    

    
    /**
     Start playing movie or episode locally.
     
     - Parameter fromFileOrMagnetLink:  The url pointing to a .torrent file, a web adress pointing to a .torrent file to be downloaded or a magnet link.
     - Parameter nextEpisodeInSeries:   If media is an episode, pass in the next episode of the series, if applicable, for a better UX for the user.
     - Parameter finishedLoadingBlock:  Block thats called when torrent is finished loading.
     */
    func play(
        fromFileOrMagnetLink url: String,
        nextEpisodeInSeries nextEpisode: Episode? = nil,
        finishedLoadingBlock: @escaping () -> Void)
    {
        let playBlock: (URL, URL, Media, Episode?) -> Void = { (videoFileURL, videoFilePath, media, nextEpisode) in
            DispatchQueue.main.async {
                let playerModel = PlayerViewModel(media: media, fromUrl: videoFileURL, localUrl: videoFilePath, directory: videoFilePath.deletingLastPathComponent(), streamer: self.streamer!)
                playerModel.startPosition = self.watchedProgress
                finishedLoadingBlock()
                self.playerModel = playerModel
                self.onReadyToPlay(playerModel)
            }
        }
        
        if hasDownloaded, let download = associatedDownload {
            download.play { (videoFileURL, videoFilePath) in
                self.streamer = download
                playBlock(videoFileURL, videoFilePath, self.media, nextEpisode)
            }
            return
        }
        
        if isDownloading, let download = associatedDownload {
            download.play { (videoFileURL, videoFilePath) in
                self.streamer = download
                playBlock(videoFileURL, videoFilePath, self.media, nextEpisode)
            }
            return
        }
        
        let loadingBlock: (PTTorrentStatus) -> Void = { status in
            self.isProcessing = false
            self.progress = status.bufferingProgress
            self.speed = Int(status.downloadSpeed)
            self.seeds = Int(status.seeds)
        }
        let errorBlock: (Error) -> Void = { error in
            self.error = error
            self.showError = true
        }

        
        if url.hasPrefix("magnet") || (url.hasSuffix(".torrent") && !url.hasPrefix("http")) {
            self.streamer = PTTorrentStreamer()
            self.streamer!.startStreaming(fromMultiTorrentFileOrMagnetLink: url, progress: { (status) in
                loadingBlock(status)
            }, readyToPlay: { (videoFileURL, videoFilePath) in
                playBlock(videoFileURL, videoFilePath, self.media, nextEpisode)
            }, failure: { error in
                DispatchQueue.main.async {
                    errorBlock(error)
                }
            }, selectFileToStream: { fileNames, fileSizes in
                let description = zip(fileNames, fileSizes)
                    .map {"\($0) - \(ByteCountFormatter.string(fromByteCount:Int64(truncating: $1), countStyle: .binary))"}
                    .joined(separator:"\n")
                print("torrent files:", description)
                
                return self.selectFileToStream(fileNames: fileNames, fileSizes: fileSizes)
            })
        } else {
            Task { @MainActor in
                do {
                    let fileUrl = try await PopcornKit.downloadTorrentFile(url)
                    self.play(fromFileOrMagnetLink: fileUrl.absoluteString, nextEpisodeInSeries: nil, finishedLoadingBlock: finishedLoadingBlock)
                } catch {
                    errorBlock(error)
                }
            }
        }
    }
    
    /// The download, either completed or downloading, that is associated with this media object.
    var associatedDownload: PTTorrentDownload? {
        let id = self.media.id
        let array = PTTorrentDownloadManager.shared().activeDownloads + PTTorrentDownloadManager.shared().completedDownloads
        return array.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == id})
    }
    
    /// Boolean value indicating whether the media is currently downloading.
    var isDownloading: Bool {
        let id = self.media.id
        return PTTorrentDownloadManager.shared().activeDownloads.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == id}) != nil
    }
    
    /// Boolean value indicating whether the media has been downloaded.
    var hasDownloaded: Bool {
        let id = self.media.id
        return PTTorrentDownloadManager.shared().completedDownloads.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == id}) != nil
    }
    
    var isNotEnoughSpaceError: Bool {
        if let error = error as NSError?, error.code == -4 && error.domain == "com.popcorntimetv.popcorntorrent.error" {
            return true
        }
        return false
    }
    
    func selectFileToStream(fileNames: [String], fileSizes: [NSNumber]) -> Int32 {
        if fileNames.count == 1 {
            return Int32(0)
        }
        
        var files = Array(zip(fileNames, fileSizes).enumerated())
        
        /// for series, keep only files with format: E01
        if let episode = self.media as? Episode {
            let findByEpisode = String(format: "E%02d", episode.episode)
            files = files.filter { index, item in
                item.0.lowercased().contains(findByEpisode.lowercased())
            }
        }
        
        /// the biggest file
        let max = files.max { $0.element.1.int64Value < $1.element.1.int64Value  }
        if let biggestFileIndex = max?.offset { //
            return Int32(biggestFileIndex)
        }
        
        // let user select
        DispatchQueue.main.async {
            self.filesToPlay = fileNames
            self.showFileToPlay = true
        }
        while self.selectedFileToPlay == nil {
            sleep(1)
            print("hold")
        }
        let index = fileNames.firstIndex(of: self.selectedFileToPlay!)!
        return Int32(index)
    }
}
