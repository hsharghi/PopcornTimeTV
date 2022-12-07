//
//  SecondaryScreen.swift
//  PopcornTime
//
//  Created by Alexandru Tudose on 04.10.2022.
//  Copyright © 2022 PopcornTime. All rights reserved.
//

import SwiftUI
import Combine

final class ExternalDisplayContent: ObservableObject {
    @Published var view: AnyView?
    var isShowingOnExternalDisplay = false
}

/// Observer when a new display is connected
struct SecondaryScreen: ViewModifier {
    @State var additionalWindows: [UIWindow] = []
    @StateObject var displayContent = ExternalDisplayContent()

    private var screenDidConnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didConnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var screenDidDisconnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didDisconnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func body(content: Content) -> some View {
        content
            .environmentObject(displayContent)
            .onReceive(screenDidConnectPublisher, perform: screenDidConnect)
            .onReceive(screenDidDisconnectPublisher, perform: screenDidDisconnect)
    }

    private func screenDidDisconnect(_ screen: UIScreen) {
        additionalWindows.removeAll { $0.screen == screen }
        displayContent.isShowingOnExternalDisplay = false
    }


    private func screenDidConnect(_ screen: UIScreen) {
        let window = UIWindow(frame: screen.bounds)

        window.windowScene = UIApplication.shared.connectedScenes
            .first { ($0 as? UIWindowScene)?.screen == screen }
            as? UIWindowScene
        
        screen.overscanCompensation = .scale

        let view = ExternalView(screen: screen)
            .environmentObject(displayContent)
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        controller.view.bounds = screen.bounds
        controller.view.backgroundColor = UIColor.red
        window.isHidden = false
        additionalWindows.append(window)
        
        displayContent.isShowingOnExternalDisplay = true
    }
}
