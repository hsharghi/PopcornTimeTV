//
//  MoviesView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct MoviesView: View, MediaRatingsLoader {
    static let theme = Theme()
    
    @StateObject var viewModel = MoviesViewModel()
    let columns = [
        GridItem(.adaptive(minimum: theme.itemWidth), spacing: theme.itemSpacing)
    ]
    
    var body: some View {
        ZStack(alignment: .leading) {
            errorView
            ScrollView {
                #if os(iOS)
                filtersView
                #endif
                LazyVGrid(columns: columns, spacing: MoviesView.theme.columnSpacing) {
                    ForEach(viewModel.movies, id: \.id) { movie in
                        navigationLink(movie: movie)
                    }
                    if (!viewModel.movies.isEmpty) {
                        loadingView
                    }
                }
                .padding(.all, 0)
                
                if viewModel.isLoading && viewModel.movies.isEmpty {
                    ProgressView()
                }
            }
            .padding(.horizontal)
            .onAppear {
                if viewModel.movies.isEmpty {
                    viewModel.loadMovies()
                }
            }
            #if os(tvOS)
            LeftSidePanelView(currentSort: $viewModel.currentFilter, currentGenre: $viewModel.currentGenre)
                .padding(.leading, -50)
            #endif
        }
        #if os(macOS)
        .modifier(VisibleToolbarView(toolbarContent: { isVisible in
            ToolbarItem(placement: .navigation) {
                if isVisible {
                    filtersView
                }
            }
        }))
        #endif
                                
        #if os(tvOS) || os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.appDidBecomeActive()
        }
        #endif
        #if os(iOS)
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    func navigationLink(movie: Movie) -> some View {
        NavigationLink(
            destination: { MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)) },
            label: {
                MovieView(movie: movie)
            })
            .buttonStyle(PlainNavigationLinkButtonStyle(onFocus: {
                Task {
                    await loadRatingIfMissing(media: movie, into: $viewModel.movies)
                }
            }))
            .padding([.leading, .trailing], 10)
    }
    
    @ViewBuilder
    var loadingView: some View {
        Text("")
            .onAppear {
                viewModel.loadMore()
            }
        if viewModel.isLoading {
            ProgressView()
        }
    }
    
    @ViewBuilder
    var errorView: some View {
        if let error = viewModel.error, viewModel.movies.isEmpty {
            HStack() {
                Spacer()
                ErrorView(error: error)
                    .padding(.bottom, 100)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var filtersView: some View {
        HStack(spacing: 0) {
            Picker("Movies", selection: $viewModel.currentFilter) {
                ForEach(Popcorn.Filters.allCases, id: \.self) { item in
                    Text(item.string).tag(item)
                }
            }
            #if os(iOS)
            Text("Movies   -   Genre")
            #endif
            Picker("Genre", selection: $viewModel.currentGenre) {
                ForEach(Popcorn.Genres.allCases, id: \.self) { item in
                    Text(item.string).tag(item)
                }
            }
        }
        .foregroundColor(.appSecondary)
        .font(.callout)
    }
}

extension MoviesView {
    struct Theme {
        let itemWidth: CGFloat = value(tvOS: 240, macOS: 160)
        let itemSpacing: CGFloat = value(tvOS: 30, macOS: 20)
        let columnSpacing: CGFloat = value(tvOS: 60, macOS: 30)
    }
}

struct MoviesView_Previews: PreviewProvider {
    static var previews: some View {
        let model = MoviesViewModel()
        model.movies = Movie.dummiesFromJSON()
        return MoviesView(viewModel: model)
            .preferredColorScheme(.dark)
            .accentColor(.white)
    }
}
