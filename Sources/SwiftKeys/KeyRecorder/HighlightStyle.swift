//===----------------------------------------------------------------------===//
//
// HighlightStyle.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

extension KeyRecorder {
  /// Styles that affect the highlighted appearance of a key recorder.
  public enum HighlightStyle: CaseIterable {
    /// A light highlight style.
    case light
    
    /// A medium-light highlight style.
    case mediumLight
    
    /// A dark highlight style.
    case dark
    
    /// An ultra-dark highlight style.
    case ultraDark
    
    var highlightColor: NSColor {
      var color: NSColor
      switch self {
      case .light: color = .white
      case .mediumLight, .dark: color = .gray
      case .ultraDark: color = .black
      }
      return color.withAlphaComponent(0.75)
    }
    
    var material: NSVisualEffectView.Material {
      if #unavailable(macOS 10.14) {
        switch self {
        case .light: return .light
        case .mediumLight: return .mediumLight
        case .dark: return .dark
        case .ultraDark: return .ultraDark
        }
      } else {
        switch self {
        case .light: return .selection
        case .mediumLight: return .titlebar
        case .dark: return .windowBackground
        case .ultraDark: return .underPageBackground
        }
      }
    }
  }
}
