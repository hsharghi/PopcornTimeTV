//
//  EpisodeView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 04.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct EpisodeView: View {
    struct Theme {
        let imageWidth: CGFloat = value(tvOS: 340, macOS: 227)
        let imageHeight: CGFloat = value(tvOS: 200, macOS: 141)
        let fontSize: CGFloat = value(tvOS: 28, macOS: 16)
    }
    let theme = Theme()
    
    var episode: Episode
    var onFocus: () -> Void = {}
    @EnvironmentObject var viewModel: ShowDetailsViewModel
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        KFImage(URL(string: episode.smallBackgroundImage ?? ""))
            .resizable()
            .placeholder {
                Image("Episode Placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: theme.imageWidth, height: theme.imageHeight)
            .clipped()
            .overlay(alignment: .topLeading) {
                airDateOverlay
            }
            .overlay(alignment: .bottomLeading) {
                episodeNameLabel
            }
            .overlay(alignment: .bottomTrailing) {
                if episode.isWatched {
                    Image("Episode Watched Indicator")
                }
            }
            .cornerRadius(10)
            .overlay {
                #if os(iOS) || os(macOS)
                if isFocused {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color(white: 1, opacity: 0.6) : .clear, lineWidth: 1.0)
                }
                #endif
            }
            .shadow(radius: 5)
        .drawingGroup()
        .onAppear {
            viewModel.loadImageIfMissing(episode: episode)
        }
        .onChange(of: isFocused, perform: { newValue in
            if newValue {
                onFocus()
            }
        })
    }
    
    @ViewBuilder
    var airDateOverlay: some View {
        if showAirdate {
            HStack {
                airDateLabel
                    .padding([.top, .bottom, .trailing], 8)
                Spacer()
            }
            .background {
                LinearGradient(gradient: Gradient(colors: [.clear, .init(white: 0.0, opacity: 0.3)]), startPoint: .bottom, endPoint: .top)
            }
        }
    }
    
    @ViewBuilder
    var airDateLabel: some View {
        let airDateString = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
        Text(airDateString)
            .font(.caption2)
            .foregroundColor(.init(white: 1.0, opacity: 0.92))
            .shadow(color: .init(white: 0, opacity: 0.7), radius: 4)
            .padding(.leading, 10)
    }
    
    @ViewBuilder
    var episodeNameLabel: some View {
        HStack {
            Text("\(episode.episode). " + episode.title)
                .font(.system(size: theme.fontSize, weight: .regular))
                .lineLimit(1)
                .shadow(color: .init(white: 0, opacity: 0.7), radius: 4)
                .foregroundColor(isFocused ? .white : .init(white: 1, opacity: 0.8))
                .padding(5)
            Spacer(minLength: 0)
        }
        .background {
            LinearGradient(gradient: Gradient(colors: [.clear, .init(white: 0.0, opacity: 0.6)]), startPoint: .top, endPoint: .bottom)
        }
    }
    
    var showAirdate: Bool {
        return isFocused
    }
}

struct EpisodeView_Previews: PreviewProvider {
    static var previews: some View {
        let episode = Episode(JSON: showEpisodesJSON[0])!
        Group {
            EpisodeView(episode: episode)
            #if os(iOS) || os(macOS)
                .environment(\.isFocused, true)
            #endif
            EpisodeView(episode: episode)
        }
            .environmentObject(ShowDetailsViewModel(show: episode.show!))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .background(.blue)
    }
}
