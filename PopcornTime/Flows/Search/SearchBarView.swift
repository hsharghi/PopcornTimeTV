//
//  SearchBarView.swift
//  SearchBarView
//
//  Created by Alexandru Tudose on 05.09.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
 
    var body: some View {
        HStack {
            TextField("Search ...", text: $text)
                .focused($isFocused)
                .padding(7)
                .padding(.horizontal, 25)
            #if os(iOS)
                .background(Color(.systemGray6))
            #endif
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                 
                        if isFocused && text.count > 0 {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                                    .padding([.top, .leading, .bottom])
                            }
                        }
                    }
                )
 
            if isFocused {
                Button(action: {
//                    self.text = ""
                    self.isFocused = false
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .frame(height: 36)
                .transition(.move(edge: .trailing))
                .animation(.default, value: true)
            }
        }
//        .statusBar(hidden: isFocused)
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBarView(text: .constant(""))
                .padding()
            Spacer()
        }
        
        SearchBarView(text: .constant("23"))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
