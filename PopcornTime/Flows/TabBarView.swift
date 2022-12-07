//
//  TabBarView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

struct CurrentTabKey: EnvironmentKey {
    static var defaultValue: TabBarView.Selection = .movies
}
extension EnvironmentValues {
    var currentTab: TabBarView.Selection {
        get { self[CurrentTabKey.self] }
        set { self[CurrentTabKey.self] = newValue }
    }
}

struct TabBarView: View {
    enum Selection: Int {
        case movies = 0, shows, watchlist, search, downloads, settings
    }
    @State var selectedTab = Selection.movies
    #if os(macOS)
    @State var isVisible = false
    @State var isSearching = false
    #endif
    
    @StateObject var searchModel = SearchViewModel()
    
    var body: some View {
        #if os(iOS) || os(tvOS)
        TabView(selection: $selectedTab) {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    #if os(iOS)
                    Text("Search")
                    #endif
                }
                .tag(Selection.search)
            MoviesView()
                .tabItem {
                    #if os(iOS)
                    Image("Movies On").renderingMode(.template)
                    #endif
                    Text("Movies")
                }
                .tag(Selection.movies)
            ShowsView()
                .tabItem {
                    #if os(iOS)
                    Image("Shows On").renderingMode(.template)
                    #endif
                    Text("Shows")
                }
                .tag(Selection.shows)
            WatchlistView()
                .tabItem {
                    #if os(iOS)
                    Image("Watchlist On").renderingMode(.template)
                    #endif
                    Text("Watchlist")
                }
                .tag(Selection.watchlist)
            DownloadsView()
                .tabItem {
                    #if os(iOS)
                    Image(systemName: "square.and.arrow.down")
                    #endif
                    Text("Downloads")
                }
                .tag(Selection.downloads)
            #if os(tvOS) || os(iOS)
            SettingsView()
                .tabItem {
                    #if os(iOS)
                    Image("Settings On").renderingMode(.template)
                    #endif
                    Text("Settings")
                }
                .tag(Selection.settings)
            #endif
            
        }
        .environment(\.currentTab, selectedTab)
        .ignoresSafeArea()
        #elseif os(macOS)
        ZStack {
            MoviesView()
                .hide(selectedTab != .movies)
            ShowsView()
                .hide(selectedTab != .shows)
            WatchlistView()
                .hide(selectedTab != .watchlist)
            SearchView(viewModel: searchModel)
                .hide(selectedTab != .search)
            DownloadsView()
                .hide(selectedTab != .downloads)
            ProxySearchStateView(searching: $isSearching)
        }
        .environment(\.currentTab, selectedTab)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                if selectedTab == .search {
                    Picker("", selection: $searchModel.selection) {
                         Text("Movies").tag(SearchViewModel.SearchType.movies)
                         Text("Shows").tag(SearchViewModel.SearchType.shows)
                         Text("People").tag(SearchViewModel.SearchType.people)
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker("", selection: $selectedTab) {
                        Text("Movies").tag(Selection.movies)
                        Text("Shows").tag(Selection.shows)
                        Text("Watchlist").tag(Selection.watchlist)
                        Text("Downloads").tag(Selection.downloads)
                        //                     Image(systemName: "magnifyingglass").tag(Selection.search)
                    }
                    .pickerStyle(.segmented)
                }   
            }
        })
        .searchable(text: $searchModel.search)
        .onChange(of: selectedTab) { newValue in
            if selectedTab != .search && isSearching {
                isSearching = false
            }
        }
        .onChange(of: isSearching) { newValue in
            if selectedTab != .search && isSearching {
                selectedTab = .search
            } else if selectedTab == .search && !isSearching {
                selectedTab = .movies
            }
        }
        #endif
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .preferredColorScheme(.dark)
            .tint(.white)
    }
}
