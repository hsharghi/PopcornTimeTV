//
//  DownloadView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 25.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornTorrent
import PopcornKit
import Kingfisher

struct DownloadView: View {
    struct Theme {
        let titleSize: CGFloat = value(tvOS: 28, macOS: 20)
        let detailSize: CGFloat = value(tvOS: 20, macOS: 16)
    }
    let theme = Theme()
    
    @StateObject var viewModel: DownloadViewModel
    @State var showDeleteAction = false
    @State var showActions = false
    @State var showPlayer = false
    
    var body: some View {
        Button(action: {
            showActions = true
        }, label: {
            VStack {
                Color.clear
                    .background {
                        KFImage(URL(string: viewModel.imageUrl))
                            .resizable()
                            .placeholder {
                                Image(viewModel.placeholderImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .aspectRatio(contentMode: .fill)
                            .overlay(alignment: .bottomTrailing) {
                                if viewModel.watched {
                                    Image("Episode Watched Indicator")
                                }
                            }
                    }
                    .overlay(alignment: .bottom) {
                        if viewModel.download.downloadStatus == .downloading {
                            ProgressView(value: viewModel.download.torrentStatus.totalProgress)
                                .padding([.leading, .trailing, .bottom], 15)
                        }
                    }
                    .clipped()
                    .cornerRadius(10)
                    .shadow(radius: 5)
                
                Text(viewModel.title)
                    .font(.system(size: theme.titleSize, weight: .medium))
                    .lineLimit(1)
                    .shadow(color: .init(white: 0, opacity: 0.6), radius: 2, x: 0, y: 1)
                    .padding(0)
                
                Text(viewModel.detailText)
                    .font(.system(size: theme.detailSize, weight: .medium))
                    .lineLimit(1)
                    .shadow(color: .init(white: 0, opacity: 0.6), radius: 2, x: 0, y: 1)
                    .padding(0)
            }
        })
        .buttonStyle(PlainNavigationLinkButtonStyle())
        .confirmationDialog("Are you sure you want to delete the download?", isPresented: $showDeleteAction, titleVisibility: .visible, actions: {
            deleteAction
        })
        .confirmationDialog(viewModel.title, isPresented: $showActions, titleVisibility: .visible, actions: {
            downloadActions
        })
        .fullScreenContent(isPresented: $showPlayer, title: viewModel.media.title) {
            TorrentPlayerView(torrent: viewModel.torrent, media: viewModel.media)
        }
        .onAppear {
            viewModel.addObserver()
        }
        .onDisappear {
            viewModel.observation = nil
        }
    }
    
    @ViewBuilder
    var deleteAction: some View {
        Button(role: .destructive, action: {
            viewModel.delete()
        }, label: {
            Text("Delete")
        })
    }
    
    @ViewBuilder
    var downloadActions: some View {
        let deleteDownload = Button(role: .destructive, action: {
            showDeleteAction = true
        }, label: {
            Text("Delete Download")
        })
        
        let playDownload = Button(action: {
            showPlayer = true
        }, label: {
            Text("Play")
        })
        
        let pauseDownload = Button(action: {
            viewModel.pause()
        }, label: {
            Text("Pause")
        })
        
        switch viewModel.download.downloadStatus {
        case .finished:
            Button(action: {
                showPlayer = true
            }, label: {
                Text("Play")
            })
            
            deleteDownload
        case .processing:
            pauseDownload
        case .downloading:
            pauseDownload
            playDownload
        case .paused:
            Button(action: {
                viewModel.continueDownload()
            }, label: {
                Text("Continue Download")
            })
        
            deleteDownload
        case .failed:
            deleteDownload
        @unknown default: EmptyView()
        }
    }
}

extension View {
    fileprivate func disableObserverOnAppear(viewModel: DownloadViewModel) -> some View {
        onAppear {
            viewModel.observation = nil
        }
        .onDisappear {
            viewModel.addObserver()
        }
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummy(status: .processing)))
//                .previewDisplayName("Processing")

//            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummyEpisode(status: .paused)))
//                .previewDisplayName("Paused")
            
//            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummy(status: .failed)))
//                .previewDisplayName("Failed")
            
            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummyEpisode(status: .downloading)))
                .previewDisplayName("Downloading")
        
//            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummy(status: .downloading)))
//                .previewDisplayName("Downloading")
            
//            DownloadView(viewModel: DownloadViewModel(download: PTTorrentDownload.dummy(status: .finished)))
//                .previewDisplayName("Finished")
        }
        .frame(width: 310, height: 245)
        .previewLayout(.sizeThatFits)
    }
}




