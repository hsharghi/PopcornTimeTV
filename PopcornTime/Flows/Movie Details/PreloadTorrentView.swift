//
//  PreloadTorrentView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct PreloadTorrentView: View {
    @StateObject var viewModel: PreloadTorrentViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black
            VStack {
                Spacer()
                Text(viewModel.media.title)
                    .font(.title3)
                    .padding(.bottom, 20)
                progressView
                #if os(iOS)
                cancelButton
                    .padding(.top, 20)
                #endif
                Spacer()
            }.onAppear {
                viewModel.playTorrent()
            }.onDisappear {
                viewModel.cancel()
            }
            .alert(isPresented: $viewModel.showError, content: {
                errorAlert
            })
            #if os(iOS) || os(tvOS)
            .confirmationDialog("Select file to play", isPresented: $viewModel.showFileToPlay, titleVisibility: .visible, actions: {
                chooseFilesButtons(fileNames: viewModel.filesToPlay)
            })
            #elseif os(macOS)
            .popover(isPresented: $viewModel.showFileToPlay, content: {
                VStack {
                    Text("Select file to play")
                    chooseFilesButtons(fileNames: viewModel.filesToPlay)
                        .controlSize(.large)
                }
                .font(.system(size: 16))
                .padding(20)
            })
            #endif
        }
        .accentColor(.white)
    }
    
    @ViewBuilder
    var progressView: some View {
        if viewModel.isProcessing {
            ProgressView()
        } else {
            VStack {
                ProgressView(value: $viewModel.progress.wrappedValue)
                Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.speed), countStyle: .binary) + "/s")
                Text("\(viewModel.seeds) " + "Seeds".localized.localizedLowercase)
            }
            .foregroundColor(.gray)
            #if os(tvOS)
            .font(.system(size: 30, weight: .medium))
            .frame(width: 600)
            #else
            .frame(width: 350)
            #endif
        }
    }
    
    @ViewBuilder
    var cancelButton: some View {
        Button {
            withAnimation {
                dismiss()
            }
        } label: {
            Text("CANCEL")
                .foregroundColor(.blue)
        }

    }
    
    var errorAlert: Alert {
        if viewModel.isNotEnoughSpaceError {
            return Alert(title: Text("Error"),
                         message: Text(viewModel.error?.localizedDescription ?? ""),
                         primaryButton: .default(Text("Clear All Cache"), action: {
                            viewModel.clearCache.emptyCache()
                            viewModel.error = nil
                            viewModel.playTorrent()
                        }),
                         secondaryButton: .cancel(Text("Cancel"), action: {
                            dismiss()
                        })
            )
        } else {
            return Alert(title: Text("Error"),
                  message: Text(viewModel.error?.localizedDescription ?? ""),
                  dismissButton: .cancel(Text("Cancel"), action: {
                    dismiss()
                  }))
        }
    }
    
    @ViewBuilder
    func chooseFilesButtons(fileNames: [String]) -> some View  {
        ForEach(fileNames, id: \.self) { fileName in
            Button {
                viewModel.selectedFileToPlay = fileName
                viewModel.showFileToPlay = false
            } label: {
                Text(fileName)
                #if os(macOS)
                Spacer()
                #endif
            }
        }
    }
}

struct PreloadTorrentView_Previews: PreviewProvider {
    static var previews: some View {
        let model = PreloadTorrentViewModel(torrent: Torrent(), media: Movie.dummy(), onReadyToPlay: {_ in })
        PreloadTorrentView(viewModel: model)
            .preferredColorScheme(.dark)
        
        PreloadTorrentView(viewModel: progressModel)
            .preferredColorScheme(.dark)
    }
    
    static var progressModel: PreloadTorrentViewModel {
        let progressModel = PreloadTorrentViewModel(torrent: Torrent(), media: Movie.dummy(), onReadyToPlay: {_ in })
        progressModel.progress = 0.4
        progressModel.speed = 20000
        progressModel.seeds = 10
        progressModel.isProcessing = false
        return progressModel
    }
}
