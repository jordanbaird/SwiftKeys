//
//  BezelStyle.swift
//  SwiftKeys
//

import AppKit

// MARK: - KeyRecorder BezelStyle

extension KeyRecorder {
    /// A type that represents the visual style used to display a ``KeyRecorder``'s
    /// bezel.
    public enum BezelStyle: CaseIterable, Hashable {
        /// The key recorder is displayed with a rounded rectangular bezel.
        case rounded

        /// The key recorder is displayed with a small capsule-like bezel with a flat
        /// appearance and a solid line border.
        case capsule

        /// The key recorder is displayed with a rounded rectangular bezel with a flat
        /// appearance and a solid line border.
        case flat

        /// The key recorder is displayed so that the individual sections of its bezel
        /// do not touch.
        case separated

        /// The key recorder is displayed with a square bezel.
        case square

        /// The key recorder is displayed with a flat appearance and a solid line
        /// border.
        @available(*, deprecated, renamed: "capsule")
        public static let flatBordered: Self = .capsule
    }
}

// MARK: BezelStyle Properties
extension KeyRecorder.BezelStyle {
    var cocoaValue: NSSegmentedControl.Style {
        switch self {
        case .rounded, .flat:
            return .rounded
        case .capsule:
            return .roundRect
        case .separated:
            return .separated
        case .square:
            return .smallSquare
        }
    }
}

// MARK: BezelStyle Initializers
extension KeyRecorder.BezelStyle {
    init(cocoaValue: NSSegmentedControl.Style, default defaultStyle: @autoclosure () -> Self) {
        let style = Self.allCases.first { style in
            style.cocoaValue == cocoaValue
        }
        self = style ?? defaultStyle()
    }
}

// MARK: BezelStyle Methods
extension KeyRecorder.BezelStyle {
    func apply(to control: KeyRecorderSegmentedControl) {
        control.segmentStyle = cocoaValue
        switch self {
        case .flat:
            control.cell?.isBezeled = false
            control.borderLayer = .roundedRectBorder(for: control)
            control.splitterLayer = .segmentSplitter(for: control, afterSegment: 0)
        default:
            control.cell?.isBezeled = true
            control.borderLayer = nil
            control.splitterLayer = nil
        }
    }
}
