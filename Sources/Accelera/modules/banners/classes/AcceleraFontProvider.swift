#if ACCELERA_BANNERS_ENABLED

import UIKit
import DivKit

/// Family names select a weight; exact face names retain their registered style.
/// Register custom fonts before rendering. DivKit applies variation axes and caches the result.
final class AcceleraFontProvider: DivFontProvider {
    private static let weights: [UIFont.Weight] = [
        .ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
    ]

    func font(family: String, weight: DivFontWeight, size: CGFloat) -> UIFont {
        let value: Int = switch weight {
        case .light: 300
        case .regular: 400
        case .medium: 500
        case .bold: 700
        }
        return font(family: family, weight: value, size: size)
    }

    func font(family: String, weight: Int, size: CGFloat) -> UIFont {
        // Interpolate UIKit's weight scale instead of collapsing numeric weights into four buckets.
        let value = weight > 0 ? min(max(weight, 100), 900) : 400
        let index = (value - 100) / 100
        let lower = Self.weights[index].rawValue
        let upper = Self.weights[min(index + 1, 8)].rawValue
        let uiWeight = UIFont.Weight(lower + (upper - lower) * CGFloat(value % 100) / 100)
        let fallback = UIFont.systemFont(ofSize: size, weight: uiWeight)

        let faces = UIFont.fontNames(forFamilyName: family)
        guard !faces.isEmpty else {
            // Preserve explicit PostScript names (including Bold/Italic) for backwards compatibility.
            return UIFont(name: family, size: size) ?? fallback
        }

        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: uiWeight.rawValue]
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        // UIKit may silently substitute a different family; never treat that as a successful match.
        return faces.contains(font.fontName) ? font : fallback
    }
}

#endif
