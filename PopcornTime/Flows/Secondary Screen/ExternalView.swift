//
//  SecondaryView.swift
//  PopcornTime
//
//  Created by Alexandru Tudose on 04.10.2022.
//  Copyright © 2022 PopcornTime. All rights reserved.
//

import SwiftUI

struct ExternalView: View {
    var screen: UIScreen
    @EnvironmentObject var displayContent: ExternalDisplayContent
    
    var body: some View {
        ZStack {
            Color.appSecondary
                .overlay {
                    VStack(spacing: 20) {
                        Text("PopcornTime")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Resolution: \(Int(screen.bounds.width))x\(Int(screen.bounds.height))")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                }
            if let view = displayContent.view {
                view
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

struct SecondaryView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalView(screen: UIScreen())
            .environmentObject(ExternalDisplayContent())            
    }
}
