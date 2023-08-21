//
//  DetailView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct MovieDetailsView: View, MediaPosterLoader {
    let theme = Theme()
    
    @StateObject var viewModel: MovieDetailsViewModel
    
    var movie: Movie {
        return viewModel.movie
    }
    @Namespace var section1
    
    var body: some View {
            ZStack {
                backgroundImage()
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack {
                            Color.clear.overlay {
                                Text(movie.title)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .minimumScaleFactor(0.01)
                                    .font(theme.titleFont)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    
                            }
                            .padding(.bottom, 50)
                            .padding(.top, 200)
                            .padding(.leading, -theme.leftSectionLeading)
                                
                            HStack(alignment: .top, spacing: 40) {
                                leftSection
                                    .hideIfPhone()
                                rightSection(scroll: scroll)
                                Spacer()
                            }
                            .padding(.leading, 10)
                            #if os(iOS)
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                ScrollView(.horizontal) {
                                    actionButtons(scroll: nil)
                                        .padding([.leading, .top, .bottom], 10)
                                }
                            } else {
                                actionButtons(scroll: nil)
                                    .padding(.top, 10)
                            }
                            #endif
                        }
                        .padding(.leading, theme.leftSectionLeading)
                        .frame(idealHeight: theme.section1Height)
                        .id(section1)
                        #if os(tvOS)
                        .focusSection()
                        #endif
                        
                        VStack {
                            if viewModel.related.count > 0 {
                                alsoWatchedSection
                                    #if os(tvOS)
                                    .focusSection()
                                    #endif
                            }
                            if viewModel.persons.count > 0 {
                                ActorsCrewView(persons: $viewModel.persons)
                                #if os(tvOS)
                                .focusSection()
                                #endif
                            }
                        }
                        #if os(tvOS)
                        .padding([.bottom, .top], 30)
                        #else
                        .padding([.bottom], 30)
                        #endif
                        .background(Color.init(white: 1, opacity: 0.3))
                        .padding(.top, theme.section1PaddingBottom)
                    }
                }
                if let error = viewModel.error ?? viewModel.trailerModel.error {
                    BannerView(error: error)
                        .padding([.trailing], theme.bannerTrailing)
                        .padding([.top], theme.bannertop)
                        .transition(.move(edge: .top))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                viewModel.trailerModel.error = nil
                            }
                        }
                }
            }.onAppear {
//                viewModel.playSongTheme()
                viewModel.load()
            }.onDisappear {
//                viewModel.stopTheme()
            }
        .ignoresSafeArea()
    }
    
    func backgroundImage() -> some View {
        Color.clear
            .background(
                KFImage(viewModel.backgroundUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding(0)
            )
            .overlay(
                Color(white: 0, opacity: theme.backgroundOpacity))
            .clipped()
    }
    
    @ViewBuilder
    var leftSection: some View {
        VStack(alignment: .trailing, spacing: 40) {
            if let genre = movie.genres.first?.localizedCapitalized.localized {
                sectionText(title: "Genre".localized.localizedUppercase, description: [genre])
            }
            
            let directors = movie.crew.filter({$0.roleType == .director}).prefix(5).compactMap{String($0.name)}
            let isSingular = directors.count == 1
            if directors.count > 0
                {
                sectionText(title: (isSingular ? "Director".localized.localizedUppercase : "Directors".localized.localizedUppercase), description: directors)
            }
            
            let showActorsCount = max(6 - directors.count, 1)
            let actors = movie.actors.prefix(showActorsCount).compactMap{ String($0.name) }
            if !actors.isEmpty {
                sectionText(title: "Starring".localized.localizedUppercase, description: actors)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .frame(width: theme.leftSectionWidth)
    }
    
    @ViewBuilder
    func rightSection(scroll: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: theme.rightSectionSpacing) {
            infoText
            RatingsView(viewModel: RatingsViewModel(media: movie, ratings: movie.ratings))
            Color.clear
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(movie.summary)
                        awards()
                    }
                }
            #if os(tvOS)
                .frame(width: 920)
            #else
                .frame(maxWidth: 900)
            #endif
            #if os(tvOS) || os(macOS)
            actionButtons(scroll: scroll)
            #endif
        }
    }
    
    @ViewBuilder
    func actionButtons(scroll: ScrollViewProxy?) -> some View {
        HStack(spacing: 24) {
            TrailerButton(viewModel: viewModel.trailerModel)
            PlayButton(media: movie)
            watchlistButton
            watchedButton
            DownloadButton(viewModel: viewModel.downloadModel)
        }
        .buttonStyle(TVButtonStyle(onFocus: {
            #if os(tvOS)
            withAnimation {
                scroll?.scrollTo(section1, anchor: .top)
            }
            #endif
        }))
    }
    
    var infoText: some View {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        let runtime = formatter.string(from: TimeInterval(movie.runtime) * 60)
        let year = movie.year
        
        let items = [runtime, year].compactMap({$0}).map{Text($0)}
        let certifications = ([movie.certification, "HD", "CC"]).filter{ !$0.isEmpty }.map {
                Text(Image($0).renderingMode(.template))
            }
        return HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 25) {
            ForEach(0..<items.count, id: \.self) { item in
                items[item]
            }
            
            ForEach(0..<certifications.count, id: \.self) { item in
                certifications[item]
            }
            .hideIfPhone()
            
            StarRatingView(rating: movie.rating / 20)
                .frame(width: theme.starSize.width, height: theme.starSize.height)
                .padding(.top, theme.starOffset)
        }
    }
    
    @ViewBuilder
    func sectionText(title: String, description: [String]) -> some View {
        VStack(alignment: .trailing) {
            Text(title)
                .font(.system(size: theme.leftSectionTitle, weight: .bold))
                .foregroundColor(.appLightGray)
            ForEach(description, id: \.self) { item in
                Text(item)
            }
            .font(.system(size: theme.leftSectionTitleContent, weight: .medium))
            .foregroundColor(.appGray)
        }
    }
    
    var watchlistButton: some View {
        return Button(action: {
            viewModel.movie.isAddedToWatchlist.toggle()
            print(#function, viewModel.movie.isAddedToWatchlist)
        }, label: {
            VStack {
                VisualEffectBlur() {
                    movie.isAddedToWatchlist ? Image("Remove") : Image("Add")
                }
                Text("Watchlist")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    var watchedButton: some View {
        return Button(action: {
            viewModel.movie.isWatched.toggle()
        }, label: {
            VStack {
                VisualEffectBlur() {
                    movie.isWatched ? Image("Watched On") : Image("Watched Off")
                }
                Text("Watched")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    var alsoWatchedSection: some View {
        VStack (alignment: .leading) {
            Text("Viewers Also Watched")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.leading, theme.watchedSection.leading)
                .padding(.top, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: theme.watchedSection.spacing) {
                    ForEach(viewModel.related, id: \.id) { movie in
                        NavigationLink(
                            destination: MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)),
                            label: {
                                MovieView(movie: movie, lineLimit: 1)
                                    .frame(width: theme.watchedSection.cellWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadPosterIfMissing(media: movie, mediaPosters: $viewModel.related)
                            }
                    }
                }
                .padding(.horizontal, theme.watchedSection.leading)
                #if os(tvOS)
                .padding([.top, .bottom], 20) // on focus zoom will not be clipped
                #endif
            }
        }
        .frame(height: theme.watchedSection.height)
        .padding(0)
        .background(
            Color(white: 0, opacity: 0.3)
                .padding([.bottom], -10)
            #if os(tvOS)
                .padding([.top], -30)
            #endif
        )
    }
    
    @ViewBuilder
    func awards() -> some View {
        if let awards = movie.ratings?.awards {
            Text("Awards: " + awards)
                .font(.caption)
        }
    }
}

extension MovieDetailsView {
    struct Theme {
        let buttonWidth: CGFloat = value(tvOS: 142, macOS: 100)
        let buttonHeight: CGFloat = value(tvOS: 115, macOS: 81)
        let leftSectionTitle: CGFloat = value(tvOS: 24, macOS: 16)
        let leftSectionTitleContent: CGFloat = value(tvOS: 31, macOS: 18)
        let leftSectionWidth: CGFloat = value(tvOS: 340, macOS: 200)
        var leftSectionLeading: CGFloat { value(tvOS: 100, macOS: 30, compactSize: 10) }
        let starSize: CGSize = value(tvOS: CGSize(width: 220, height: 40), macOS: CGSize(width: 110, height: 20))
        let starOffset: CGFloat = value(tvOS: -8, macOS: -4)
        var watchedSection: (height: CGFloat, cellWidth: CGFloat, spacing: CGFloat, leading: CGFloat) {
             (height: value(tvOS: 450, macOS: 280),
               cellWidth: value(tvOS: 220, macOS: 150),
               spacing: value(tvOS: 80, macOS: 30),
               leading: value(tvOS: 90, macOS: 50, compactSize: 20)) }
        let backgroundOpacity = value(tvOS: 0.3, macOS: 0.5)
        let titleFont: Font = Font.system(size: value(tvOS: 76, macOS: 50, compactSize: 40), weight: .medium)
        let section1Height: CGFloat = value(tvOS: 960, macOS: 710)
        let section1PaddingBottom: CGFloat = value(tvOS: 50, macOS: 20)
        let rightSectionSpacing: CGFloat = value(tvOS: 50, macOS: 30)
        let bannerTrailing: CGFloat = value(tvOS: 60, macOS: 60, compactSize: 20)
        let bannertop: CGFloat = value(tvOS: 60, macOS: 60, compactSize: 100)
    }
}

struct MovieDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MovieDetailsView(viewModel: viewModel())
            #if os(tvOS)
//                .previewLayout(.fixed(height: 1800))
            #endif
            
            MovieDetailsView(viewModel: errorViewModel())
                .previewDisplayName("Error")
            
            MovieDetailsView(viewModel: loadingViewModel())
                .previewDisplayName("Loading")
        }
        .preferredColorScheme(.dark)
//        .previewInterfaceOrientation(.landscapeLeft)
    }
    
    static func viewModel() -> MovieDetailsViewModel {
        let movie = Movie.dummiesFromJSON()[3]
        let viewModel = MovieDetailsViewModel(movie: movie)
        viewModel.related = Movie.dummy().related
        viewModel.persons = Movie.dummy().actors
        viewModel.didLoad = true
        return viewModel
    }
    
    static func loadingViewModel() -> MovieDetailsViewModel {
        let movie = Movie.dummiesFromJSON()[0]
        let viewModel = MovieDetailsViewModel(movie: movie)
        viewModel.isLoading = true
        return viewModel
    }
    
    static func errorViewModel() -> MovieDetailsViewModel {
        let viewModel = MovieDetailsViewModel(movie: Movie.dummy())
        let error = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is an error text example"])
        viewModel.error = error
        viewModel.didLoad = true
        return viewModel
    }
}
