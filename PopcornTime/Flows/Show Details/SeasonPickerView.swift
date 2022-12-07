//
//  SeasonPickerView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct SeasonPickerView: View, SeasonPosterLoader {
    @StateObject var viewModel: SeasonPickerViewModel
    @Binding var selectedSeasonNumber: Int
    @Environment(\.dismiss) var dismiss
    #if os(tvOS)
    @FocusState var focusedField: Int?
    #endif
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            }
            VStack {
                Text(viewModel.show.title)
                    .font(.title)
                ScrollViewReader { scroll in
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(viewModel.seasons, id: \.number) { season in
                                Button(action: {
                                    selectedSeasonNumber = season.number
                                    dismiss()
                                }, label: {
                                    SeasonView(season: season)
                                })
                                .buttonStyle(PlainButtonStyle(onFocus: {}))
                                #if os(tvOS)
                                .focused($focusedField, equals: season.number)
                                #endif
                                .task {
                                    await loadPosterIfMissing(season: season, show: viewModel.show, into: $viewModel.seasons)
                                }
                            }
                        }
                        .padding()
                    }.onAppear {
                        scroll.scrollTo(selectedSeasonNumber, anchor: .center)
                    }
                }
            }
        }
        .onAppear {
            viewModel.load()
            #if os(tvOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedField = selectedSeasonNumber
            }
            #endif
        }
    }
}

struct SeasonPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let show = Show.dummy()
        let viewModel = SeasonPickerViewModel(show: show)
        return SeasonPickerView(viewModel: viewModel, selectedSeasonNumber: .constant(1))
    }
}
