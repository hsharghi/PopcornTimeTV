//
//  EpisodesView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Combine

struct EpisodesView: View {
    let theme = Theme()
    
    var show: Show
    var episodes: [Episode]
    var currentSeason: Int
    @State var currentEpisode: Episode? {
        didSet {
            downloadModel = currentEpisode.flatMap{ DownloadButtonViewModel(media: $0)}
        }
    }
    @State var downloadModel: DownloadButtonViewModel?
    @State var showTorrent: PlayTorrentEpisode?
    
    var onFocus: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading) {
            #if os(tvOS)
            titleView
            #endif
            episodesCountView
            ScrollViewReader { scroll in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: theme.episodeSpacing) {
                        ForEach(episodes, id: \.episode) { episode in
                            episodeView(episode: episode, scroll: scroll)
                        }
                    }
                    .padding([.top, .bottom], 20) // allow zooming to be visible
                    #if os(tvOS)
                    .padding(.bottom, 55) // allow card style - shadow to be visible
                    #endif
                    .padding([.leading, .trailing], theme.leading)
                }
                .onAppear {
                    if let episode = currentEpisode {
                        currentEpisode = episode /// so that downloadModel is created in didSet
                        scroll.scrollTo(episode.episode, anchor: theme.scrollPosition)
                    }
                }
            }
            currentEpisodeView
            #if os(tvOS)
                .padding(.top, -55) // revert back on top, because of focused shadow
                .focusSection()
            #endif
        }
        .fullScreenContent(item: $showTorrent, title: show.title, content: { item in
            TorrentPlayerView(torrent: item.torrent,
                              media: item.episode,
                              nextEpisode: NextEpisode(episode: item.episode, show: show).next())
        })
        .onChange(of: episodes) { newValue in
            if currentEpisode == nil {
                currentEpisode = newValue.first
            }
        }
    }
    
    @ViewBuilder
    var titleView: some View {
        HStack {
            Spacer()
            Text(show.title)
                .font(.title2)
            Spacer()
        }
    }
    
    @ViewBuilder
    func episodeView(episode: Episode, scroll: ScrollViewProxy) -> some View {
        let isSelected = episode.id == currentEpisode?.id && episode.episode == currentEpisode?.episode
        SelectTorrentQualityButton(media: episode, action: { torrent in
            self.currentEpisode = episode
            showTorrent = PlayTorrentEpisode(torrent: torrent, episode: episode)
        }, label: {
            EpisodeView(episode: episode, onFocus: {
                #if os(tvOS)
                onFocus()
                currentEpisode = episode
//                scroll.scrollTo(episode.episode, anchor: .leading)
                #endif
            })
            #if os(iOS) || os(macOS)
                .environment(\.isFocused, isSelected)
            #endif
        })
        .frame(width: theme.episodeWidth, height: theme.episodeHeight)
        #if os(tvOS)
        .buttonStyle(.card)
        #else
        .buttonStyle(TVButtonStyle(onFocus: {}, onPressed:{
            currentEpisode = episode
        }, isSelected: isSelected))
        #endif
    }
    
    var episodesCountView: some View {
        let localizedSeason = NumberFormatter.localizedString(from: NSNumber(value: currentSeason), number: .none)
        let seasonString = "Season".localized + " \(localizedSeason)"
        let count = episodes.count
        let isSingular = count == 1
        let numberOfEpisodes = "\(NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)) \(isSingular ? "Episode".localized : "Episodes".localized)"
        var year = ""
        if let date = episodes.first?.firstAirDate {
            let components = Calendar.current.dateComponents([.year], from: date)
            year = components.year.flatMap({ "\($0)" }) ?? ""
        }
        
        return Text("\(seasonString) (\(numberOfEpisodes.lowercased())) - \(year)")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.leading, theme.leading)
                .padding(.top, 14)
    }
    
    @ViewBuilder
    var currentEpisodeView: some View {
        if let episode = currentEpisode {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(episode.episode). " + episode.title)
                        .font(.headline)
                    HStack {
                        Text(episode.summary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: theme.currentEpisode.trailing)
                            .hideIfCompactSize()
                    }
                    if episode == currentEpisode, let downloadModel = downloadModel {
                        DownloadButton(viewModel: downloadModel)
                            .buttonStyle(TVButtonStyle(onFocus: onFocus))
                    }
                }
                .padding([.leading], theme.currentEpisode.leading + 10)
                Spacer()
            }
            .frame(height: theme.currentEpisode.height)
        }
    }
}

extension EpisodesView {
    struct Theme {
        let episodeWidth: CGFloat = value(tvOS: 330, macOS: 227)
        let episodeHeight: CGFloat = value(tvOS: 200, macOS: 141)
        let episodeSpacing: CGFloat = value(tvOS: 40, macOS: 24)
        var currentEpisode: (leading: CGFloat, height: CGFloat, trailing: CGFloat)
            { (leading: value(tvOS: 90, macOS: 50, compactSize: 20),
               height: value(tvOS: 350, macOS: 250),
               trailing: value(tvOS: 500, macOS: 200)) }
        var leading: CGFloat { value(tvOS: 90, macOS: 50, compactSize: 20) }
        
        let scrollPosition: UnitPoint? = value(tvOS: nil, macOS: nil)
    }
}

struct EpisodesView_Previews: PreviewProvider {
    static var previews: some View {
        let show = Show.dummy()
        let episode = show.episodes.first!
        let downloadModel = DownloadButtonViewModel(media: show)
        let showDetails = ShowDetailsViewModel(show: show)
        
        Group {
            ScrollView {
                EpisodesView(show: show, episodes: show.episodes, currentSeason: 0, currentEpisode: episode, downloadModel: downloadModel)
                    .environmentObject(showDetails)
            }
            
            ScrollView {
                EpisodesView(show: show, episodes: show.episodes, currentSeason: 0, currentEpisode: episode)
                    .environmentObject(showDetails)
            }
        }
            .preferredColorScheme(.dark)
            .background(.gray)
    }
}
