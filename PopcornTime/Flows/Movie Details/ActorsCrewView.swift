//
//  Actors&CrewView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 05.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct ActorsCrewView: View, CharacterHeadshotLoader {
    struct Theme {
        let height: CGFloat = value(tvOS: 321, macOS: 218)
        let cellWidth: CGFloat = value(tvOS: 220, macOS: 150)
        let spacing: CGFloat = value(tvOS: 80, macOS: 30)
        var leading: CGFloat { value(tvOS: 90, macOS: 50, compactSize: 20) }
    }
    let theme = Theme()
    
    @Binding var persons: [Person]
    
    var body: some View {
        return VStack(alignment: .leading) {
            Text("Cast & Crew")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.leading, theme.leading)
                .padding(.top, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                Spacer()
                     .frame(height: 30) // on focus zoom will not be clipped
                LazyHStack(alignment: .center, spacing: theme.spacing) {
                    ForEach(0..<persons.count, id: \.self) { index in
                        personView(person: persons[index])
                            .task {
                                await loadHeadshotIfMissing(person: persons[index], into: $persons)
                            }
                    }
                }
                .padding(.horizontal, theme.leading)
                Spacer()
            }
            .frame(height: theme.height)
        }
        .padding(0)
    }
    
    @ViewBuilder
    func personView(person: Person) -> some View {
        NavigationLink(
            destination: PersonDetailsView(viewModel: PersonDetailsViewModel(person: person)),
            label: {
                PersonView(person: person, radius: theme.cellWidth)
                    .frame(width: theme.cellWidth)
            })
            .buttonStyle(PlainNavigationLinkButtonStyle())
    }
}

struct ActorsCrewView_Previews: PreviewProvider {
    static var previews: some View {
        let show = Show.dummy()
        ActorsCrewView(persons: .constant(show.actors + show.crew))
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
