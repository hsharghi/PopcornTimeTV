//
//  WatchlistViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 05.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

class WatchlistViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var shows: [Show] = []
    var didSyncWithTrack = false
    
    init() {
        
    }
    
    func load() {
        self.movies = WatchlistManager<Movie>.movie.getWatchlist().reversed() // newest first
        self.shows = WatchlistManager<Show>.show.getWatchlist().reversed() //.sorted(by: {$0.title < $1.title})
        
        if !didSyncWithTrack {
            Task { @MainActor in
                didSyncWithTrack = true
                try await TraktApi.shared.refreshWatchlist()
                self.movies = WatchlistManager<Movie>.movie.getWatchlist().reversed() // newest first
                self.shows = WatchlistManager<Show>.show.getWatchlist().reversed() //.sorted(by: {$0.title < $1.title})
            }
        }
    }
    
}
