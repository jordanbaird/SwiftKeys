//===----------------------------------------------------------------------===//
//
// BezelStyle.swift
//
//===----------------------------------------------------------------------===//

import AppKit

extension KeyRecorder {
    /// Styles that a key recorder's bezel can be drawn in.
    public enum BezelStyle: CaseIterable, Hashable {
        /// The default style.
        case rounded

        /// A rounded, rectangular style with a flat appearance and a solid line border.
        case flatBordered

        /// A style where the individual segments of the recorder do not touch.
        case separated

        /// A square style.
        case square

        // MARK: Properties

        var rawValue: NSSegmentedControl.Style {
            switch self {
            case .rounded: return .rounded
            case .flatBordered: return .roundRect
            case .separated: return .separated
            case .square: return .smallSquare
            }
        }

        var widthConstant: CGFloat {
            switch self {
            case .rounded: return -4
            case .flatBordered: return -4
            case .separated: return -2
            case .square: return -2
            }
        }

        var heightConstant: CGFloat {
            switch self {
            case .rounded: return -2
            case .flatBordered: return -6
            case .separated: return 0
            case .square: return -4
            }
        }

        // MARK: Initializers

        init?(_ rawValue: NSSegmentedControl.Style) {
            let style = Self.allCases.first {
                $0.rawValue == rawValue
            }
            guard let style else {
                return nil
            }
            self = style
        }
    }
}
