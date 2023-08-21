//
//  ShowDetailsViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 04.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import PopcornKit
import SwiftUI
import Combine

class ShowDetailsViewModel: ObservableObject {
    @Published var show: Show
    @Published var error: Error?
    @Published var currentSeason = -1 {
        didSet {
            latestUnwatchedEpisode = show.latestUnwatchedEpisode(from: self.seasonEpisodes())
            self.trailerModel = TrailerButtonViewModel(show: self.show, season: currentSeason)
            self.trailerErrorObserver = trailerModel.$error.sink(receiveValue: { [unowned self] error in
                self.objectWillChange.send()
            })
        }
    }
    
    @Published var isLoading = false
    @Published var didLoad = false
    var latestUnwatchedEpisode: Episode?
    @Published var persons: [Person] = []
    @Published var related: [Show] = []
    @ObservedObject var trailerModel: TrailerButtonViewModel
    var trailerErrorObserver: AnyCancellable?
    
    init(show: Show) {
        self.show = show
        self.trailerModel = TrailerButtonViewModel(show: show, season: 1)
        self.trailerErrorObserver = trailerModel.$error.sink(receiveValue: { [unowned self] error in
            self.objectWillChange.send()
        })
    }
    
    var backgroundUrl: URL? {
        return URL(string: show.largeBackgroundImage ?? "")
    }
    
    func load() {
        guard !isLoading, !didLoad else {
            return
        }
        
        if show.ratings == nil {
            Task { @MainActor in
                let info = try? await OMDbApi.shared.loadInfo(imdbId: show.id)
                if let info = info {
                    self.show.ratings = info.transform()
                }
            }
        }
        
        isLoading = true
        Task { @MainActor in
            do  {
                async let related = TraktApi.shared.getRelated(self.show)
                async let people = TraktApi.shared.getPeople(forMediaOfType: .shows, id: self.show.id)
                async let tmdbIdLoader = TraktApi.shared.getTMDBId(forImdbId: show.id)
                
                var show = try await PopcornKit.getShowInfo(show.id)
                show.largeBackgroundImage = self.show.largeBackgroundImage ?? show.largeBackgroundImage //keep last background
                show.ratings = self.show.ratings
                self.show = show
                self.didLoad = true
                
                guard let season = show.latestUnwatchedEpisode()?.season ?? show.seasonNumbers.first else {
                    let error = NSError(domain: "com.popcorntimetv.popcorntime.error", code: -243, userInfo:
                                            [NSLocalizedDescriptionKey: "There are no seasons available for the selected show. Please try again later.".localized])
                    self.error = error
                    return
                }
                
                // load tmdbId so we can show episode preview
                if show.tmdbId == nil, let tmdbId = try? await tmdbIdLoader {
                    self.show.tmdbId = tmdbId
                }
                self.currentSeason = season
                
                self.related = (try? await related) ?? []
                let persons = (try? await people) ?? (actors: [], crew: [])
                self.persons = persons.actors + persons.crew
            } catch {
                self.error = error
            }
            self.isLoading = false
        }
    }
    
    func playSongTheme() {
        if let tvdbId = Int(show.tvdbId) {
            ThemeSongManager.shared.playShowTheme(tvdbId)
        }
    }
    
    func stopTheme() {
        ThemeSongManager.shared.stopTheme()
    }
    
    func seasonEpisodes() -> [Episode] {
        return show.episodes.filter({$0.season == currentSeason}).sorted(by: {$0.episode < $1.episode})
    }
    
    func nextEpisodeToWatch() -> Episode? {
        return latestUnwatchedEpisode ?? seasonEpisodes().first
    }
    
    func loadImageIfMissing(episode: Episode) {
        guard episode.smallBackgroundImage == nil, let tmdbId = show.tmdbId else {
            return
        }
        
        Task { @MainActor in
            let image = try? await TMDBApi.shared.getEpisodeScreenshots(tmdbId: tmdbId, season: episode.season, episode: episode.episode)
            if let index = self.show.episodes.firstIndex(where: {$0.id == episode.id }) {
                self.show.episodes[index].largeBackgroundImage = image ?? ""
            }
        }
    }
}
