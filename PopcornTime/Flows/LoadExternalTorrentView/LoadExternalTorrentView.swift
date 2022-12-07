//
//  LoadExternalTorrentView.swift
//  PopcornTime (tvOS)
//
//  Created by Alexandru Tudose on 19.09.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

struct LoadExternalTorrentView: View {
    @StateObject var viewModel = LoadExternalTorrentViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VisualEffectBlur()
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Please navigate to the webpage \n\(viewModel.displayUrl)\n and insert the magnet link of the torrent you would like to play")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 900)
                Spacer()
                Button("Return") {
                    dismiss()
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenContent(item: $viewModel.playTorrent, title: viewModel.playTorrent?.movie.title ?? "", content: { item in
            TorrentPlayerView(torrent: item.torrent, media: item.movie)
        })
        .onAppear {
            viewModel.startServer()
        }
        .onDisappear {
            viewModel.stopServer()
        }
    }
}

struct LoadExternalTorrentView_Previews: PreviewProvider {
    static var previews: some View {
        LoadExternalTorrentView()
    }
}
