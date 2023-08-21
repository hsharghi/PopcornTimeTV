//
//  DetailViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 20.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation
import PopcornKit
import AVKit
import SwiftUI
import Combine

class MovieDetailsViewModel: ObservableObject, CharacterHeadshotLoader, MediaRatingsLoader, MediaPosterLoader {
    @Published var movie: Movie
    @Published var error: Error?
    
    @Published var isLoading = false
    @Published var didLoad = false
    @Published var persons: [Person] = []
    @Published var related: [Movie] = []
    
    var trailerModel: TrailerButtonViewModel
    var downloadModel: DownloadButtonViewModel
    var trailerErrorObserver: AnyCancellable?
    
    init(movie: Movie) {
        self.movie = movie
        self.trailerModel = TrailerButtonViewModel(movie: movie)
        self.downloadModel = DownloadButtonViewModel(media: movie)
        self.trailerErrorObserver = trailerModel.$error.sink(receiveValue: { [unowned self] error in
            self.objectWillChange.send()
        })
    }
    
    func load() {
        guard !isLoading, !didLoad else {
            return
        }
        
        if movie.ratings == nil {
            Task { @MainActor in
                let info = try? await OMDbApi.shared.loadInfo(imdbId: movie.id)
                if let info = info {
                    self.movie.ratings = info.transform()
                }
            }
        }
        
        isLoading = true
        Task { @MainActor in
            do {
                async let related = TraktApi.shared.getRelated(self.movie)
                async let people = TraktApi.shared.getPeople(forMediaOfType: .movies, id: self.movie.id)
                
                var movie = try await PopcornKit.getMovieInfo(movie.id)
                movie.ratings = self.movie.ratings
                movie.largeBackgroundImage = self.movie.largeBackgroundImage ?? movie.largeBackgroundImage //keep last background
                self.movie = movie
                self.downloadModel = DownloadButtonViewModel(media: movie)
                
                let persons = (try? await people) ?? (actors: [], crew: [])
                self.related = (try? await related) ?? []
                self.persons = persons.actors + persons.crew
                self.movie.actors = persons.actors
                self.movie.crew = persons.crew
                self.didLoad = true
            } catch {
                self.error = error
            }
            self.isLoading = false
        }
    }
    
    var backgroundUrl: URL? {
        return URL(string: movie.largeBackgroundImage ?? "")
    }
    
    func playSongTheme() {
        ThemeSongManager.shared.playMovieTheme(movie.title)
    }
    
    func stopTheme() {
        ThemeSongManager.shared.stopTheme()
    }
}
