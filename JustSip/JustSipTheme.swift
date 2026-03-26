import SwiftUI
import UIKit

extension Color {
    static let justSipBackground = adaptive(
        light: UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1.0),
        dark: UIColor(red: 0.11, green: 0.09, blue: 0.08, alpha: 1.0)
    )
    static let justSipCardBackground = adaptive(
        light: UIColor(red: 0.995, green: 0.99, blue: 0.975, alpha: 1.0),
        dark: UIColor(red: 0.17, green: 0.14, blue: 0.12, alpha: 1.0)
    )
    static let justSipOverviewBackground = adaptive(
        light: UIColor(red: 0.96, green: 0.92, blue: 0.87, alpha: 1.0),
        dark: UIColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 1.0)
    )
    static let justSipInsetBackground = adaptive(
        light: UIColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 0.72),
        dark: UIColor(red: 0.29, green: 0.23, blue: 0.19, alpha: 0.92)
    )
    static let justSipTrackBackground = adaptive(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.58),
        dark: UIColor(red: 0.39, green: 0.31, blue: 0.25, alpha: 1.0)
    )
    static let justSipMutedFill = adaptive(
        light: UIColor(red: 0.19, green: 0.15, blue: 0.12, alpha: 0.08),
        dark: UIColor(red: 0.67, green: 0.56, blue: 0.47, alpha: 0.22)
    )
    static let justSipShadowColor = adaptive(
        light: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.06),
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.26)
    )
    static let justSipAccent = adaptive(
        light: UIColor(red: 0.80, green: 0.49, blue: 0.27, alpha: 1.0),
        dark: UIColor(red: 0.86, green: 0.60, blue: 0.38, alpha: 1.0)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
