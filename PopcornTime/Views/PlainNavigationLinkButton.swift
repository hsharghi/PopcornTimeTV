import SwiftUI

struct PlainNavigationLinkButtonStyle: ButtonStyle {
    var onFocus: () -> Void = {}
    
    func makeBody(configuration: Self.Configuration) -> some View {
        PlainNavigationLinkButton(configuration: configuration, onFocus: onFocus)
    }
}

fileprivate struct Theme {
    let scaleEffect: CGFloat = value(tvOS: 1.1, macOS: 0.95)
}

struct PlainNavigationLinkButton: View {
    private let theme = Theme()
    #if os(tvOS)
    @Environment(\.isFocused) var focused: Bool
    #elseif os(macOS) || os(iOS)
    @State var focused: Bool = false
    #endif
    let configuration: ButtonStyle.Configuration
    var onFocus: () -> Void = {}

    var body: some View {
        configuration.label
            #if os(tvOS)
            .scaleEffect(focused ? theme.scaleEffect : 1)
            #elseif os(macOS)
            .overlay(overlayColor)
            .onHover { hover in
                if hover {
                    onFocus()
                }
                focused = hover
            }
            #endif
            .foregroundColor((focused || configuration.isPressed) ? Color.primary : Color.appSecondary)
            .animation(.easeOut, value: focused)
            #if os(iOS)
            .compositingGroup()
            .overlay(overlayColor)
            .environment(\.isButtonPress, configuration.isPressed)
            #endif
            .onChange(of: focused) { newValue in
                if newValue {
                    onFocus()
                }
            }
            .onChange(of: configuration.isPressed) { newValue in
                if newValue {
                    onFocus()
                }
            }
    }
    
    /// highlight effect
    @ViewBuilder
    var overlayColor: some View {
        #if os(iOS) || os(tvOS)
        let show = configuration.isPressed
        #elseif os(macOS)
        let show = focused
        #endif
        
        if show {
            Color(white: 0, opacity: 0.3).mask(configuration.label)
        } else {
            EmptyView()
        }
    }
}




struct PlainButtonStyle: ButtonStyle {
    let onFocus: () -> Void
    
    func makeBody(configuration: Self.Configuration) -> some View {
        PlainButton(configuration: configuration, onFocus: onFocus)
    }
}

struct PlainButton: View {
    private let theme = Theme()
    @Environment(\.isFocused) var focused: Bool
    let configuration: ButtonStyle.Configuration
    let onFocus: () -> Void

    var body: some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(focused || configuration.isPressed ? theme.scaleEffect : 1)
            .foregroundColor((focused || configuration.isPressed) ? .primary : .appGray)
            .animation(.easeOut, value: focused)
            .onChange(of: focused) { newValue in
                if newValue {
                    onFocus()
                }
            }
    }
}


#if os(iOS)
struct ButtonPressKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isButtonPress: Bool {
        get { self[ButtonPressKey.self] }
        set { self[ButtonPressKey.self] = newValue }
    }
}
#endif
