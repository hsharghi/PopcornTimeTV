//
//  InfoView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct InfoView: View {
    let theme = Theme()
    let media: Media?
    
    var body: some View {
        if let media = media {
            HStack(spacing: 0) {
                KFImage(URL(string: media.smallCoverImage ?? ""))
                    .resizable()
                    .placeholder {
                        Image("Movie Placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.bottom, 5)
                    .padding(.trailing, theme.leading * 0.5)
                    .frame(maxWidth: theme.imageMaxWidth)
                VStack(alignment: .leading, spacing: 0) {
                    Text(media.title)
                        .lineLimit(1)
                        .font(.system(size: theme.sectionFontSize, weight: .medium))
                        .foregroundColor(.appGray)
                        .padding(.bottom, 10)
                    infoText
                        .lineLimit(1)
                        .font(.system(size: theme.sectionFontSize, weight: .medium))
                        .foregroundColor(.appGray)
                        .padding(.bottom, 4)
                    Text(media.summary)
                        .font(.system(size: theme.contentFontSize, weight: .medium))
                        .foregroundColor(.appGray)
                        .frame(maxHeight: 140)
                        .padding(.bottom, 4)
//                    Spacer()
                }
            }
            .padding(0)
            .padding([.leading, .trailing], theme.leading)
        } else {
            Text("No info available.")
                .font(.system(size: theme.noContentFontSize, weight: .medium))
                .foregroundColor(.appGray)
        }
    }
    
//    @ViewBuilder
    var infoText: some View {
        if let movie = media as? Movie {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            let runtime = formatter.string(from: TimeInterval(movie.runtime) * 60)
            let year = movie.year
            
            let items = [Text([runtime, year].compactMap({$0}).joined(separator: "\t"))]
                + ([movie.certification, "HD", "CC"]).map {
                    Text(Image($0).renderingMode(.template))
                }
            return HStack(alignment: .center, spacing: 25) {
                ForEach(0..<items.count, id: \.self) { item in
                    items[item]
                }
            }
        } else {
            return HStack(alignment: .center, spacing: 25) {
                ForEach(0..<[""].count, id: \.self) { item in
                    Text("")
                }
            }
        }
    }
}

extension InfoView {
    struct Theme {
        let sectionFontSize: CGFloat = value(tvOS: 32, macOS: 20, compactSize: 20)
        let contentFontSize: CGFloat = value(tvOS: 30, macOS: 18)
        let noContentFontSize: CGFloat = value(tvOS: 35, macOS: 23)
        let leading: CGFloat = value(tvOS: 80, macOS: 40, compactSize: 10)
        let imageMaxWidth: CGFloat = value(tvOS: 400, macOS: 200, compactSize: 150)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InfoView(media: Movie.dummy())
            InfoView(media: nil)
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
