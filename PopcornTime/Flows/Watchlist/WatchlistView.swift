//
//  WatchlistView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct WatchlistView: View, MediaPosterLoader {
    let theme = Theme()
    
    @StateObject var viewModel = WatchlistViewModel()
    
    var body: some View {
        ZStack {
            emptyView
            ScrollView {
                if viewModel.movies.count > 0 {
                    movieSection
                }
                if viewModel.shows.count > 0 {
                    showSection
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var movieSection: some View {
        VStack(alignment: .leading) {
            Text("Movies")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
                .padding(.leading, theme.leading)
            ScrollView(.horizontal) {
                LazyHStack(spacing: theme.itemSpacing) {
                    ForEach(viewModel.movies, id: \.self) { movie in
                        NavigationLink(
                            destination: MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)),
                            label: {
                                MovieView(movie: movie)
                                    .frame(width: theme.itemWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadPosterIfMissing(media: movie, mediaPosters: $viewModel.movies)
                            }
//                            .padding([.leading, .trailing], 10)
                    }
                    .padding(20) // allow zoom
                }
                .padding(.all, 0)
                .padding(.leading, theme.leading)
            }
        }
        
    }
    
    @ViewBuilder
    var showSection: some View {
        VStack(alignment: .leading) {
            Text("Shows")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
                .padding(.leading, theme.leading)
            ScrollView(.horizontal) {
                LazyHStack(spacing: theme.itemSpacing) {
                    ForEach(viewModel.shows, id: \.self) { show in
                        NavigationLink(
                            destination: ShowDetailsView(viewModel: ShowDetailsViewModel(show: show)),
                            label: {
                                ShowView(show: show)
                                    .frame(width: theme.itemWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadPosterIfMissing(media: show, mediaPosters: $viewModel.shows)
                            }
//                            .padding([.leading, .trailing], 10)
                    }
                    .padding(20) // allow zoom
                }
                .padding(.all, 0)
                .padding(.leading, theme.leading)
            }
        }
    }
    
    @ViewBuilder
    var emptyView: some View {
        if viewModel.shows.isEmpty && viewModel.movies.isEmpty {
            VStack {
                Text("Watchlist Empty")
                    .font(.title2)
                    .padding()
                Text("Try adding movies or shows to your watchlist.")
                    .font(.callout)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: 400)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

extension WatchlistView {
    struct Theme {
        let itemWidth: CGFloat = value(tvOS: 240, macOS: 160)
        let itemSpacing: CGFloat = value(tvOS: 40, macOS: 20, compactSize: 10)
        let leading: CGFloat = value(tvOS: 50, macOS: 50, compactSize: 10)
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // empty list
            WatchlistView(viewModel: WatchlistViewModel())
            
            let moviesModel = WatchlistViewModel()
            WatchlistView(viewModel: moviesModel)
                .onAppear {
                    DispatchQueue.main.async {
                        moviesModel.movies = Movie.dummiesFromJSON()
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}
