//
//  TrailerButton.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 21.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import AVKit
import PopcornKit

struct TrailerButton: View {
    struct Theme {
        let buttonWidth: CGFloat = value(tvOS: 142, macOS: 100)
        let buttonHeight: CGFloat = value(tvOS: 115, macOS: 81)
    }
    let theme = Theme()
    
    var viewModel: TrailerButtonViewModel
    @State var playerObservation: Any?
    @State var showPlayer = false
    
    var body: some View {
        Button(action: {
            showTrailer()
        }, label: {
            VStack {
                VisualEffectBlur() {
                    Image("Preview")
                }
                Text("Trailer")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
        .fullScreenContent(isPresented: $showPlayer, title: viewModel.media.title) {
            trailerVideo
        }
    }
    
    var trailerVideo: some View {
        VideoPlayer(player: viewModel.trailerVidePlayer)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    viewModel.trailerVidePlayer?.play()
                }
                
                self.playerObservation = NotificationCenter.default.addObserver(forName:.AVPlayerItemDidPlayToEndTime, object:nil, queue: .main, using: {_ in
                    self.showPlayer = false
                })
            }
            .onDisappear {
                onPlayerClose()
            }
            #if os(iOS)
            .overlay(alignment: .topLeading, content: {
                if #available(iOS 16, *) {
                    closeButton
                        .position(x:20, y:35)
                }
            })
            #endif
            .ignoresSafeArea()
    }
    
    func onPlayerClose() {
        viewModel.trailerVidePlayer?.pause()
        viewModel.trailerVidePlayer?.seek(to: .zero)
        self.playerObservation = nil
    }
    
    func showTrailer() {
        viewModel.error = nil
        Task {
            do {
                try await viewModel.loadTrailerUrl()
                self.showPlayer = true
            } catch {
                DispatchQueue.main.async {
                    viewModel.error = error
                }
            }
        }
    }
    
    @ViewBuilder
    var closeButton: some View {
        Button {
            withAnimation {
                showPlayer = false
            }
            onPlayerClose()
        } label: {
            Color.clear
                .overlay(Image("CloseiOS"))
        }
        .frame(width: 46, height: 46)
//        .background(.regularMaterial)
    }
}

struct TrailerButton_Previews: PreviewProvider {
    static var previews: some View {
        TrailerButton(viewModel: TrailerButtonViewModel(movie: Movie.dummy()))
            .buttonStyle(TVButtonStyle())
            .padding(40)
            .previewLayout(.fixed(width: 300, height: 300))
    }
}
