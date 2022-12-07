//
//  SecondaryScreenDisplay.swift
//  PopcornTime (iOS)
//
//  Created by Alexandru Tudose on 08.10.2022.
//  Copyright © 2022 PopcornTime. All rights reserved.
//

import SwiftUI

/// Will show content on external display if available
struct SecondaryScreenDisplay<Content: View>: View {
    @EnvironmentObject var displayContent: ExternalDisplayContent
    var content: () -> Content

    @ViewBuilder
    var body: some View {
        if displayContent.isShowingOnExternalDisplay {
            Color.init(white: 0.3)
                .overlay {
                    VStack(spacing: 20) {
                        Text("Playing on external display")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }
                .onAppear {
                    displayContent.view = AnyView(content())
                }
                .onDisappear {
                    displayContent.view = nil
                }
        } else {
            content()
        }
    }
}
struct SecondaryScreenDisplay_Previews: PreviewProvider {
    static var secondaryDisplayActive: ExternalDisplayContent {
        let displayContent = ExternalDisplayContent()
        displayContent.isShowingOnExternalDisplay = true
        return displayContent
    }
    
    static var previews: some View {
        SecondaryScreenDisplay(content: {
            Color.green
        })
        .environmentObject(self.secondaryDisplayActive)
        
        SecondaryScreenDisplay(content: {
            Color.green
        })
            .environmentObject(ExternalDisplayContent())
    }
}
