//
//  MediaRatingsLoader.swift
//  PopcornTime
//
//  Created by Alexandru Tudose on 07.08.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation
import PopcornKit
import SwiftUI

protocol MediaRatingsLoader {
    func loadRatingIfMissing(media: Movie, into mediaRatings: Binding<[Movie]>) async
    func loadRatingIfMissing(media: Show, into mediaRatings: Binding<[Show]>) async
}


extension MediaRatingsLoader {
    
    @MainActor
    func loadRatingIfMissing(media: Movie, into mediaRatings: Binding<[Movie]>) async {
        guard media.ratings == nil else {
            return
        }
        
        let info = try? await OMDbApi.shared.loadInfo(imdbId: media.id)
        if let info = info, let index = mediaRatings.wrappedValue.firstIndex(where: {$0.id == media.id}) {
            withAnimation {
                mediaRatings.wrappedValue[index].ratings = info.transform()
            }
        }
    }
    
    @MainActor
    func loadRatingIfMissing(media: Show, into mediaRatings: Binding<[Show]>) async {
        guard media.ratings == nil else {
            return
        }
        
        let info = try? await OMDbApi.shared.loadInfo(imdbId: media.id)
        if let info = info, let index = mediaRatings.wrappedValue.firstIndex(where: {$0.id == media.id}) {
            withAnimation {
                mediaRatings.wrappedValue[index].ratings = info.transform()
            }
        }
    }
}

protocol CharacterHeadshotLoader {
    func loadHeadshotIfMissing(person: Person, into persons: Binding<[Person]>) async
}

extension CharacterHeadshotLoader {
    
    @MainActor
    func loadHeadshotIfMissing(person: Person, into persons: Binding<[Person]>) async {
        guard person.largeImage == nil else {
            return
        }
        
        let url = try? await TMDBApi.shared.getCharacterHeadshots(tmdbId: person.tmdbId)
        if let index = persons.wrappedValue.firstIndex(where: {$0.tmdbId == person.tmdbId }) {
            persons.wrappedValue[index].largeImage = url ?? ""
        }
    }
}

protocol MediaPosterLoader {
    func loadPosterIfMissing(media: Movie, mediaPosters: Binding<[Movie]>) async
    func loadPosterIfMissing(media: Show, mediaPosters: Binding<[Show]>) async
}

extension MediaPosterLoader {
    
    @MainActor
    func loadPosterIfMissing(media: Movie, mediaPosters: Binding<[Movie]>) async {
        guard media.largeCoverImage == nil, let tmdbId = media.tmdbId else {
            return
        }
        
        let response = await TMDBApi.shared.getPoster(forMediaOfType: .movies, TMDBId: tmdbId)
        if let index = mediaPosters.wrappedValue.firstIndex(where: {$0.id == media.id}) {
            var media = mediaPosters.wrappedValue[index]
            media.largeCoverImage = response.poster
            media.largeBackgroundImage = response.backdrop
            mediaPosters.wrappedValue[index] = media
        }
    }
    
    @MainActor
    func loadPosterIfMissing(media: Show, mediaPosters: Binding<[Show]>) async {
        guard media.largeCoverImage == nil, let tmdbId = media.tmdbId else {
            return
        }
        
        let response = await TMDBApi.shared.getPoster(forMediaOfType: .shows, TMDBId: tmdbId)
        if let index = mediaPosters.wrappedValue.firstIndex(where: {$0.id == media.id}) {
            var media = mediaPosters.wrappedValue[index]
            media.largeCoverImage = response.poster
            media.largeBackgroundImage = response.backdrop
            mediaPosters.wrappedValue[index] = media
        }
    }
}


protocol SeasonPosterLoader {
    func loadPosterIfMissing(season: SeasonPickerViewModel.Season, show: Show, into seasons: Binding<[SeasonPickerViewModel.Season]>) async
}

extension SeasonPosterLoader {
    
    @MainActor
    func loadPosterIfMissing(season: SeasonPickerViewModel.Season, show: Show, into seasons: Binding<[SeasonPickerViewModel.Season]>) async {
        guard season.image == nil, let tmdbId = show.tmdbId else {
            return
        }
        
        let image = try? await TMDBApi.shared.getSeasonPoster(tmdbId: tmdbId, season: season.number)
        if let index = seasons.wrappedValue.firstIndex(where: {$0.number == season.number}) {
            seasons.wrappedValue[index] = .init(number: season.number, image: image ?? show.largeCoverImage)
        }
    }
}

