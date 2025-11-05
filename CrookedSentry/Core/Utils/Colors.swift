//
//  Colors.swift
//  CrookedSentry
//
//  Material 3 Design Color System
//  Created by Assistant on 2025
//

import SwiftUI

extension Color {
    // MARK: - Material 3 Color System
    // Automatically adapts to light/dark mode
    
    // MARK: - Primary Colors
    
    /// Main brand color, used for primary actions and key UI elements
    static let primary = Color(light: "#446732", dark: "#A9D291")
    
    /// Tint color for surfaces to indicate primary brand
    static let surfaceTint = Color(light: "#446732", dark: "#A9D291")
    
    /// Text/content color on primary backgrounds
    static let onPrimary = Color(light: "#FFFFFF", dark: "#173807")
    
    /// Container color for primary elements
    static let primaryContainer = Color(light: "#C5EFAB", dark: "#2D4F1D")
    
    /// Text/content color on primary containers
    static let onPrimaryContainer = Color(light: "#2D4F1D", dark: "#C5EFAB")
    
    // MARK: - Secondary Colors
    
    /// Secondary brand color, used for less prominent UI elements
    static let secondary = Color(light: "#55624C", dark: "#BCCBB0")
    
    /// Text/content color on secondary backgrounds
    static let onSecondary = Color(light: "#FFFFFF", dark: "#283421")
    
    /// Container color for secondary elements
    static let secondaryContainer = Color(light: "#D8E7CB", dark: "#3E4A36")
    
    /// Text/content color on secondary containers
    static let onSecondaryContainer = Color(light: "#3E4A36", dark: "#D8E7CB")
    
    // MARK: - Tertiary Colors
    
    /// Tertiary color for accent and complementary elements
    static let tertiary = Color(light: "#386667", dark: "#A0CFD0")
    
    /// Text/content color on tertiary backgrounds
    static let onTertiary = Color(light: "#FFFFFF", dark: "#003738")
    
    /// Container color for tertiary elements
    static let tertiaryContainer = Color(light: "#BBEBEC", dark: "#1E4E4F")
    
    /// Text/content color on tertiary containers
    static let onTertiaryContainer = Color(light: "#1E4E4F", dark: "#BBEBEC")
    
    // MARK: - Error Colors
    
    /// Error state color
    static let error = Color(light: "#BA1A1A", dark: "#FFB4AB")
    
    /// Text/content color on error backgrounds
    static let onError = Color(light: "#FFFFFF", dark: "#690005")
    
    /// Container color for error states
    static let errorContainer = Color(light: "#FFDAD6", dark: "#93000A")
    
    /// Text/content color on error containers
    static let onErrorContainer = Color(light: "#93000A", dark: "#FFDAD6")
    
    // MARK: - Surface Colors
    
    /// Primary background color
    static let background = Color(light: "#F8FAF0", dark: "#11140F")
    
    /// Text/content color on background
    static let onBackground = Color(light: "#191D16", dark: "#E1E4D9")
    
    /// Surface color for cards, sheets, and elevated components
    static let surface = Color(light: "#F8FAF0", dark: "#11140F")
    
    /// Text/content color on surface
    static let onSurface = Color(light: "#191D16", dark: "#E1E4D9")
    
    /// Variant surface color for subtle differentiation
    static let surfaceVariant = Color(light: "#DFE4D7", dark: "#43483E")
    
    /// Text/content color on surface variants
    static let onSurfaceVariant = Color(light: "#43483E", dark: "#C3C8BB")
    
    // MARK: - Outline Colors
    
    /// Primary outline color for borders and dividers
    static let outline = Color(light: "#74796D", dark: "#8D9286")
    
    /// Secondary outline color for subtle borders
    static let outlineVariant = Color(light: "#C3C8BB", dark: "#43483E")
    
    // MARK: - Surface Container Colors (Elevation Levels)
    
    /// Lowest elevation surface
    static let surfaceContainerLowest = Color(light: "#FFFFFF", dark: "#0C0F0A")
    
    /// Low elevation surface
    static let surfaceContainerLow = Color(light: "#F2F5EA", dark: "#191D16")
    
    /// Medium elevation surface
    static let surfaceContainer = Color(light: "#EDEFE5", dark: "#1D211A")
    
    /// High elevation surface
    static let surfaceContainerHigh = Color(light: "#E7E9DF", dark: "#282B24")
    
    /// Highest elevation surface
    static let surfaceContainerHighest = Color(light: "#E1E4D9", dark: "#32362F")
    
    // MARK: - Inverse Colors
    
    /// Inverse surface for high contrast elements
    static let inverseSurface = Color(light: "#2E312B", dark: "#E1E4D9")
    
    /// Text/content on inverse surface
    static let inverseOnSurface = Color(light: "#EFF2E7", dark: "#2E312B")
    
    /// Inverse primary color
    static let inversePrimary = Color(light: "#A9D291", dark: "#446732")
    
    // MARK: - Utility Colors
    
    /// Shadow color
    static let shadow = Color(light: "#000000", dark: "#000000")
    
    /// Scrim color for overlays
    static let scrim = Color(light: "#000000", dark: "#000000")
}

// MARK: - Legacy App Colors (for backward compatibility)
extension Color {
    /// Primary text color - adapts to theme
    static let appTextPrimary = Color.onSurface
    
    /// Secondary text color - adapts to theme
    static let appTextSecondary = Color.onSurfaceVariant
    
    /// Background colors - adapts to theme
    static let appBackgroundDark = Color.surfaceContainer
    static let appBackgroundBlack = Color.surface
    
    /// Status colors - using Material 3 colors
    static let appStatusOnline = Color.primary
    static let appStatusConnecting = Color.tertiary
    static let appStatusOffline = Color.error
    
    /// Accent colors - using Material 3 colors
    static let appAccentBlue = Color.primary
    static let appAccentOrange = Color.tertiary
    
    /// Border colors - adapts to theme
    static let appBorderLight = Color.outline
}

// MARK: - Color Initialization Helper
extension Color {
    /// Initialize Color with light and dark mode hex values
    init(light: String, dark: String) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: dark)
            default:
                return UIColor(hex: light)
            }
        })
    }
}

// MARK: - UIColor Extension for Hex Support
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}