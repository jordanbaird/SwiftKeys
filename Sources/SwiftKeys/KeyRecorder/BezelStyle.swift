//===----------------------------------------------------------------------===//
//
// BezelStyle.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

extension KeyRecorder {
  /// Styles that a key recorder's bezel can be drawn in.
  public enum BezelStyle: CaseIterable, Hashable {
    /// Styles available for a key recorder's border.
    /// - Note: These constants are not available for all bezel styles.
    public enum BorderStyle {
      /// The bezel is drawn with a solid border.
      case solid
      /// The bezel is drawn with a dashed border.
      case dashed
      /// The bezel style is drawn without a border.
      case noBorder
    }
    
    /// The default style.
    case rounded
    /// A rounded, rectangular style with a flat appearance and a solid line border.
    case flatBordered
    /// A style where the individual segments of the recorder do not touch, optionally drawn with a solid line border.
    case separated(_ style: BorderStyle)
    /// A square style.
    case square
    
    public static var allCases: [Self] = [
      .rounded,
      .flatBordered,
      .separated(.solid),
      .separated(.dashed),
      .separated(.noBorder),
      .square
    ]
    
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
    
    init(_ rawValue: NSSegmentedControl.Style) {
      self = Self.allCases.first { $0.rawValue == rawValue } ?? .rounded
    }
  }
}
