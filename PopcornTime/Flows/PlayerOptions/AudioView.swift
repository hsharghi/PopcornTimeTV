//
//  AudioView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import AVFoundation
import PopcornKit
import Combine

enum EqualizerProfiles: UInt32, CaseIterable, Identifiable {
    case fullDynamicRange = 0
    case reduceLoudSounds = 15
    
    var localizedString: String {
        switch self {
        case .fullDynamicRange:
            return "Full Dynamic Range".localized
        case .reduceLoudSounds:
            return "Reduce Loud Sounds".localized
        }
    }
    
    var id: UInt32 {
        return self.rawValue
    }
}

struct AudioView: View {
    let theme = Theme()
    @Binding var currentDelay: Int
    @Binding var currentSound: EqualizerProfiles
    @Binding var audioTrackIndex: Int
    var audioTracks: [String]
    @State var triggerRefresh = false
    
    let delays = (-60..<60)
    let sounds = EqualizerProfiles.allCases
    
    var body: some View {
        HStack (spacing: theme.sectionSpacing) {
            Spacer()
            delaySection
                .frame(maxWidth: 300)
                #if os(tvOS)
                .focusSection()
                #endif
            if audioTracks.count > 1 {
                audioTracksSection
                    .frame(maxWidth: 300)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
            soundSection
                #if os(tvOS)
                .focusSection()
                #endif
            Spacer()
        }
        #if os(tvOS)
        .focusSection()
        #endif
        .frame(maxHeight: 300)
    }
    
    var delaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(text: "Delay")
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(delays, id: \.self) { delay in
                            button(text: delayText(delay: delay), isSelected: delay == currentDelay, onFocus: {
                                withAnimation {
                                    scroll.scrollTo(delay, anchor: .center)
                                }
                            }) {
                                self.currentDelay = delay
                                self.triggerRefresh.toggle()
                            }
                            .id(delay)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        scroll.scrollTo(currentDelay, anchor: .center)
                    }
                }
            }
            
        }
    }
    
    var audioTracksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(text: "Audio Tracks")
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        let tracks = Array(audioTracks.enumerated())
                        ForEach(tracks, id: \.offset) { index, trackName in
                            button(text: trackName, isSelected: index == audioTrackIndex, onFocus: {
                                withAnimation {
                                    scroll.scrollTo(index, anchor: .center)
                                }
                            }) {
                                self.audioTrackIndex = index
                                self.triggerRefresh.toggle()
                            }
                            .id(index)
                        }
                    }
                }
                .onAppear(perform: {
                    scroll.scrollTo(currentDelay, anchor: .center)
                })
            }
            
        }
    }
    
    var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(text: "Sound")
            VStack(alignment: .leading, spacing: 15) {
                ForEach(sounds) { item in
                    button(text: item.localizedString, isSelected: item == currentSound, onFocus: {}) {
                        currentSound = item
                        self.triggerRefresh.toggle()
                    }
                }
            }
            Spacer()
        }
    }
    
    func delayText(delay: Int) -> String {
        return (delay > 0 ? "+" : "") + NumberFormatter.localizedString(from: NSNumber(value: delay), number: .decimal)
    }
    
    func sectionHeader(text: String) -> some View {
        Text(text.localized.uppercased())
            .font(.system(size: theme.sectionFontSize, weight: .bold))
            .foregroundColor(.appGray)
            .padding(.leading, theme.sectionLeading)
    }
    
    func button(text: String, isSelected: Bool, onFocus: @escaping () -> Void, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }, label: {
            HStack(spacing: theme.textButtonSpacing) {
                if (isSelected) {
                    Image(systemName: "checkmark")
                } else {
                    Text("").frame(width: theme.contentFontSize)
                }
                Text(text)
                    .font(.system(size: theme.contentFontSize, weight: .medium))
            }
        }).buttonStyle(PlainButtonStyle(onFocus: onFocus))
    }
}

extension AudioView {
    struct Theme {
        let sectionLeading: CGFloat = value(tvOS: 50, macOS: 50, compactSize: 5)
        let sectionSpacing: CGFloat = value(tvOS: 50, macOS: 50, compactSize: 5)
        let sectionFontSize: CGFloat = value(tvOS: 32, macOS: 20, compactSize: 17)
        let contentFontSize: CGFloat = value(tvOS: 31, macOS: 19, compactSize: 16)
        let languageSectionWidth: CGFloat = value(tvOS: 390, macOS: 250)
        let textButtonSpacing: CGFloat = value(tvOS: 20, macOS: 20, compactSize: 5)

    }
}

struct AudioView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AudioView(currentDelay: .constant(0),
                      currentSound: .constant(.fullDynamicRange),
                      audioTrackIndex: .constant(0),
                      audioTracks: [])
            
            AudioView(currentDelay: .constant(0),
                      currentSound: .constant(.fullDynamicRange),
                      audioTrackIndex: .constant(1),
                      audioTracks: ["Lang 1", "Lang 2"])
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
