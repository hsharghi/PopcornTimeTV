//
//  ShowsView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct ShowsView: View, MediaRatingsLoader {
    static let theme = Theme()
    
    @StateObject var viewModel = ShowsViewModel()
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
                LazyVGrid(columns: columns, spacing: ShowsView.theme.columnSpacing) {
                    ForEach(viewModel.shows, id: \.id) { show in
                        navigationLink(show: show)
                    }
                    if (!viewModel.shows.isEmpty) {
                        loadingView
                    }
                }
                .padding(.all, 0)
                
                if viewModel.isLoading && viewModel.shows.isEmpty {
                    ProgressView()
                }
            }
            .padding(.horizontal)
            .onAppear {
                if viewModel.shows.isEmpty {
                    viewModel.loadShows()
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
    func navigationLink(show: Show) -> some View {
        NavigationLink(
            destination: ShowDetailsView(viewModel: ShowDetailsViewModel(show: show)),
            label: {
                ShowView(show: show)
            })
            .buttonStyle(PlainNavigationLinkButtonStyle(onFocus: {
                Task {
                    await loadRatingIfMissing(media: show, into: $viewModel.shows)
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
        if let error = viewModel.error, viewModel.shows.isEmpty {
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
            Picker("Shows", selection: $viewModel.currentFilter) {
                ForEach(Popcorn.Filters.allCases, id: \.self) { item in
                    Text(item.string).tag(item)
                }
            
            }
            #if os(iOS)
            Text("Shows   -   Genre")
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

extension ShowsView {
    struct Theme {
        let itemWidth: CGFloat = value(tvOS: 240, macOS: 160)
        let itemSpacing: CGFloat = value(tvOS: 30, macOS: 20)
        let columnSpacing: CGFloat = value(tvOS: 60, macOS: 30)
    }
}

struct ShowsView_Previews: PreviewProvider {
    static var previews: some View {
        let model = ShowsViewModel()
        model.shows = Show.dummiesFromJSON()
        return ShowsView(viewModel: model)
            .preferredColorScheme(.dark)
            .accentColor(.white)
//            .previewInterfaceOrientation(.landscapeLeft)
    }
}
