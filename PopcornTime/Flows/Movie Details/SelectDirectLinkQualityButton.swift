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


struct SelectDirectLinkQualityButton<Label>: View where Label : View {
    var links: [DownloadLink]
    var media: Media
    var action: (DownloadLink) -> Void
    @ViewBuilder var label: () -> Label
    
    struct AlertType: Identifiable {
        enum Choice {
            case noLinksFound, streamOnCellular
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

            if links.count == 0 {
                alert = .init(id: .noLinksFound)
            } else {
                showChooseQualityActionSheet = true
            }
        }, label: label)
        #if os(iOS) || os(tvOS)
        .confirmationDialog("Choose Quality", isPresented: $showChooseQualityActionSheet, titleVisibility: .visible, actions: {
            chooseLinksButtons
        })
        #elseif os(macOS)
        .popover(isPresented: $showChooseQualityActionSheet, content: {
            VStack {
                Text("Choose Quality")
                chooseLinksButtons
                    .controlSize(.large)
            }
            .font(.system(size: 16))
            .padding(20)
        })
        #endif
        .alert(item: $alert) { alert in
            switch alert.id {
            case .noLinksFound:
                return Alert(title: Text("No links found"),
                      message: Text("Direct stream link could not be found for the specified media."))
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
    var chooseLinksButtons: some View {
        ForEach(links.sorted(by: >)) { link in
            Button {
                action(link)
            } label: {
                #if os(iOS) || os(tvOS)
                Text("\(link.title) | \(link.encoder) | \(link.size)")
                #elseif os(macOS)
                Text(link.title)
                Text(link.size)
                    .fontWeight(.bold)
                Text(link.encoder)
                    .foregroundColor(.appLightGray)
                    .font(.system(size: 12, weight: .light))
                Spacer()
                #endif
            }
        }
    }
}

struct SelectDirectLinkQualityAction_Previews: PreviewProvider {
    static var previews: some View {
        SelectDirectLinkQualityButton(links: DownloadLink.movieLinks, media: Movie.dummy(), action: { link in
            print("selected: ", link)
        }, label: {
            Text("Play")
        })
            .preferredColorScheme(.dark)
    }
}
