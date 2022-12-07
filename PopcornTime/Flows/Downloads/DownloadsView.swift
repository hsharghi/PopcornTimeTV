//
//  DownloadsView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import PopcornTorrent

struct DownloadsView: View {
    let theme = Theme()
    
    @StateObject var viewModel = DownloadsViewModel()
    let downloadDeleted =  NotificationCenter.default
        .publisher(for: NSNotification.Name("DownloadDeleted"))
    
    var body: some View {
        ZStack {
            if viewModel.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack {
                        if !viewModel.downloading.isEmpty {
                            downloadingSection
                        }
                        if !viewModel.completedMovies.isEmpty {
                            movieSection
                        }
                        if !viewModel.completedEpisodes.isEmpty {
                            showSection
                        }
                    }
                    .padding(.leading, theme.leading)
                }
            }
        }
        .onAppear {
            viewModel.reload()
        }
        .onReceive(downloadDeleted) { _ in
            viewModel.reload()
        }
        #if os(iOS)
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var emptyView: some View {
        VStack {
            Text("Downloads Empty")
                .font(.title2)
                .padding()
            Text("Movies and episodes you download will show up here.")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: 400)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    var downloadingSection: some View {
        VStack(alignment: .leading) {
            Text("Downloading")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
            ScrollView(.horizontal) {
                HStack(spacing: theme.itemSpacing) {
                    ForEach(viewModel.downloading, id: \.self) { download in
                        DownloadView(viewModel: DownloadViewModel(download: download))
                            .frame(width: theme.downloadingSize.width, height: theme.downloadingSize.height)
                    }
                    .padding(theme.downloadingPadding) // allow zoom
                }
                .padding(.all, 0)
            }
        }
    }
    
    @ViewBuilder
    var movieSection: some View {
        VStack(alignment: .leading) {
            Text("Movies")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
            ScrollView(.horizontal) {
                HStack(spacing: theme.itemSpacing) {
                    ForEach(viewModel.completedMovies, id: \.self) { download in
                        DownloadView(viewModel: DownloadViewModel(download: download))
                            .frame(width: theme.itemWidth, height: theme.itemHeight)
//                            .padding([.leading, .trailing], 10)
                    }
                    .padding(20) // allow zoom
                }.padding(.all, 0)
            }
        }
    }
    
    @ViewBuilder
    var showSection: some View {
        VStack(alignment: .leading) {
            Text("Episodes")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
            ScrollView(.horizontal) {
                HStack(spacing: theme.itemSpacing) {
                    ForEach(viewModel.completedEpisodes, id: \.self) { download in
                        DownloadView(viewModel: DownloadViewModel(download: download))
                            .frame(width: theme.itemWidth, height: theme.itemHeight)
                    }
                    .padding(20) // allow zoom
                }.padding(.all, 0)
            }
        }
    }
}

extension DownloadsView {
    struct Theme {
        let itemWidth: CGFloat = value(tvOS: 240, macOS: 200, compactSize: 160)
        let itemHeight: CGFloat = value(tvOS: 420, macOS: 350, compactSize: 300)
        let downloadingSize: CGSize = value(tvOS: CGSize(width: 500, height: 400) , macOS: CGSize(width: 300, height: 220))
        let downloadingPadding: CGFloat = value(tvOS: 30, macOS: 20)
        let itemSpacing: CGFloat = value(tvOS: 40, macOS: 25, compactSize: 10)
        let leading: CGFloat = value(tvOS: 50, macOS: 50, compactSize: 10)
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            activeDownloadsView
            completedDownloadsView
            DownloadsView()
        }
        .preferredColorScheme(.dark)
    }
    
    static var activeDownloadsView: some View {
        let viewModel = DownloadsViewModel()
        return DownloadsView(viewModel: viewModel)
            .onAppear {
                viewModel.downloading = [
                    .dummy(status: .downloading),
                    .dummyEpisode(status: .downloading),
                    .dummy(status: .failed),
                ]
            }
    }
    
    static var completedDownloadsView: some View {
        let viewModel = DownloadsViewModel()
        return DownloadsView(viewModel: viewModel)
            .onAppear {
                viewModel.completedMovies = [.dummy(status: .finished), .dummy(status: .finished)]
                viewModel.completedEpisodes = [.dummyEpisode(status: .finished), .dummyEpisode(status: .finished)]
            }
    }
}
