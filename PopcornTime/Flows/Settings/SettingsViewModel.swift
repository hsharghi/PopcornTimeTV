//
//  SettingsViewModel.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 31.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Network

class SettingsViewModel: ObservableObject {
    @Published var clearCache = ClearCache()
    
    @Published var isTraktLoggedIn: Bool = TraktSession.shared.isLoggedIn()
    var traktAuthorizationUrl: URL {
        return TraktAuthApi.shared.authorizationUrl(appScheme: AppScheme)
    }
    
    var lastUpdate: String {
        var date = "Never".localized
        if let lastChecked = Session.lastVersionCheckPerformedOnDate {
            date = DateFormatter.localizedString(from: lastChecked, dateStyle: .short, timeStyle: .short)
        }
        return date
    }
    
    var version: String {
        let bundle = Bundle.main
        return [bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString"), bundle.object(forInfoDictionaryKey: "CFBundleVersion")].compactMap({$0 as? String}).joined(separator: ".")
    }
    
    func validate(traktUrl: URL) {
        if traktUrl.scheme?.lowercased() == AppScheme.lowercased() {
            Task { @MainActor in
                try await TraktAuthApi.shared.authenticate(traktUrl)
                self.traktDidLoggedIn()
            }
        }
    }
    
    func traktLogout() {
        TraktSession.shared.logout()
        isTraktLoggedIn = false
    }
    
    func traktDidLoggedIn() {
        isTraktLoggedIn = true
        TraktApi.shared.syncUserData()
    }
    
    @Published var serverUrl: String = PopcornApi.shared.customBaseURL
    
    func changeUrl(_ url: String) {
        PopcornApi.changeBaseUrl(newUrl: url.isEmpty ? nil : url)
        serverUrl = PopcornApi.shared.customBaseURL
    }
    
    var networkMonitor: NWPathMonitor = {
        let monitor = NWPathMonitor()
        monitor.start(queue: .global())
        return monitor
    }()
    
    var hasCellularNetwork: Bool {
        return networkMonitor.currentPath.availableInterfaces.contains(where: {$0.type == .cellular }) || networkMonitor.currentPath.isExpensive
    }
}
