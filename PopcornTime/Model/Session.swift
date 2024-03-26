//
//  Session.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation

enum Session {
    @UserDefault(key: "tosAccepted", defaultValue: false)
    static var tosAccepted: Bool
    
    @UserDefault(key: "autoSelectQuality", defaultValue: nil)
    static var autoSelectQuality: String?
    
    @UserDefault(key: "streamOnCellular", defaultValue: false)
    static var streamOnCellular: Bool
    
    @UserDefault(key: "removeCacheOnPlayerExit", defaultValue: false)
    static var removeCacheOnPlayerExit: Bool
    
    @UserDefault(key: "themeSongVolume", defaultValue: 0.75)
    static var themeSongVolume: Float
    
    @UserDefault(key: "oauthCredentials", defaultValue: nil)
    static var oauthCredentials: Data?
    
    @UserDefault(key: "skipReleaseVersion", defaultValue: nil)
    static var skipReleaseVersion: Data?
    
    @UserDefault(key: "subtitleSettings", defaultValue: nil)
    static var subtitleSettings: Data?
    
    @UserDefault(key: "lastVersionCheckPerformedOnDate", defaultValue: nil)
    static var lastVersionCheckPerformedOnDate: Date?

    @UserDefault(key: "useDirectLinks", defaultValue: false)
    static var useDirectLinks: Bool
}
