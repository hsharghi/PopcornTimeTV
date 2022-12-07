//
//  SelectTorrentQualityAction.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 24.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Network

let networkMonitor = NWPathMonitor()

struct SelectTorrentQualityButton<Label>: View where Label : View {
    var media: Media
    var action: (Torrent) -> Void
    @ViewBuilder var label: () -> Label
    
    struct AlertType: Identifiable {
        enum Choice {
            case noTorrentsFound, streamOnCellular
        }

        var id: Choice
    }

    
    @State var showChooseQualityActionSheet = false
    @State var alert: AlertType?
    
    var body: some View {
        return Button(action: {
            if !Session.streamOnCellular && networkMonitor.currentPath.isExpensive {
                alert = .init(id: .streamOnCellular)
                return
            }
            
            if media.torrents.count == 0 {
                alert = .init(id: .noTorrentsFound)
            } else if let torrent = autoSelectTorrent {
                action(torrent)
            } else {
                showChooseQualityActionSheet = true
            }
        }, label: label)
        #if os(iOS) || os(tvOS)
        .confirmationDialog("Choose Quality", isPresented: $showChooseQualityActionSheet, titleVisibility: .visible, actions: {
            chooseTorrentsButtons
        })
        #elseif os(macOS)
        .popover(isPresented: $showChooseQualityActionSheet, content: {
            VStack {
                Text("Choose Quality")
                chooseTorrentsButtons
                    .controlSize(.large)
            }
            .font(.system(size: 16))
            .padding(20)
        })
        #endif
        .alert(item: $alert) { alert in
            switch alert.id {
            case .noTorrentsFound:
                return Alert(title: Text("No torrents found"),
                      message: Text("Torrents could not be found for the specified media."))
            case .streamOnCellular:
                return Alert(title: Text("Cellular Data is turned off for streaming"),
                      message: nil,
                      primaryButton: .default(Text("Turn On")) {
                        Session.streamOnCellular = true
                      },
                      secondaryButton: .cancel())
            }
            
        }
        .onAppear {
            if networkMonitor.queue == nil {
                networkMonitor.start(queue: .global())
            }
        }
    }
    
    var autoSelectTorrent: Torrent? {
        if let quality = Session.autoSelectQuality {
            let sorted  = media.torrents.sorted(by: <)
            let torrent = quality == "Highest" ? sorted.last! : sorted.first!
            return torrent
        }
        
        #if os(tvOS)
        if media.torrents.count == 1 {
            return media.torrents[0]
        }
        #endif
        
        return nil
    }

    @ViewBuilder
    var chooseTorrentsButtons: some View {
        ForEach(media.torrents.sorted(by: >)) { torrent in
            Button {
                action(torrent)
            } label: {
                #if os(iOS) || os(tvOS)
                Text(torrent.quality) +
                Text(" (seeds: \(torrent.seeds) - peers: \(torrent.peers))")
                #elseif os(macOS)
                torrent.health.image
                Text(torrent.quality)
                    .fontWeight(.bold)
                Text(" (seeds: \(torrent.seeds) - peers: \(torrent.peers))")
                    .foregroundColor(.appLightGray)
                    .font(.system(size: 12, weight: .light))
                Spacer()
                #endif
            }
        }
    }
}

struct SelectTorrentQualityAction_Previews: PreviewProvider {
    static var previews: some View {
        SelectTorrentQualityButton(media: Movie.dummy(), action: { torrent in
            print("selected: ", torrent)
        }, label: {
            Text("Play")
        })
            .preferredColorScheme(.dark)
    }
}
