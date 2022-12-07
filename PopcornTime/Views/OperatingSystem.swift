//
//  OperatingSystem.swift
//  PopcornTime
//
//  Created by Alexandru Tudose on 05.08.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
//#if canImport(UIKit)
//import UIKit
//var lastOrientation: UIDeviceOrientation = .unknown
//#endif

func value<T>(tvOS: T, macOS: T, compactSize: T? = nil) -> T {
    #if os(tvOS)
        return tvOS
    #elseif os(macOS)
        return macOS
    #elseif os(iOS)
    
    if UIDevice.current.userInterfaceIdiom == .phone, let compactSize = compactSize {
        let isPortrait = UIScreen.main.bounds.width < UIScreen.main.bounds.height
        return isPortrait ? compactSize : macOS
//        var orientation = UIDevice.current.orientation
//        orientation = (orientation.isPortrait || orientation.isLandscape) ? orientation : lastOrientation
//        if orientation.isPortrait {
//            lastOrientation = orientation
//            return compactSize
//        } else if orientation.isLandscape {
//            lastOrientation = orientation
//            return macOS
//        }
//        return compactSize
    } else {
        return macOS
    }
    #endif
}

struct CompactSizeClassModifier: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var sizeClass
    #endif
    
    func body(content: Content) -> some View {
        #if os(iOS)
        
//        let isPortrait = UIScreen.main.bounds.width < UIScreen.main.bounds.height
//        if isPortrait {
        if sizeClass == .compact {
            
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    
    @ViewBuilder
    func hideIfCompactSize() -> some View {
        #if os(iOS)
        let isPortrait = UIScreen.main.bounds.width < UIScreen.main.bounds.height
        if UIDevice.current.userInterfaceIdiom == .phone, isPortrait {
            
        } else {
            self
        }
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func hideIfPhone() -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            
        } else {
            self
        }
        #else
        self
        #endif
    }
}
