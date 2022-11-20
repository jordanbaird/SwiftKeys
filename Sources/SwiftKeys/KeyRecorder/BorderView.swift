//===----------------------------------------------------------------------===//
//
// BorderView.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

extension KeyRecorder {
  class BorderView: NSView {
    var borderColor: NSColor {
      didSet {
        needsDisplay = true
      }
    }

    var borderStyle: BezelStyle.BorderStyle {
      didSet {
        needsDisplay = true
      }
    }

    var borderThickness: CGFloat {
      didSet {
        needsDisplay = true
      }
    }

    var cornerRadius: CGFloat {
      didSet {
        needsDisplay = true
      }
    }

    init(
      frame: NSRect,
      borderColor: NSColor,
      borderStyle: BezelStyle.BorderStyle,
      borderThickness: CGFloat,
      cornerRadius: CGFloat
    ) {
      self.borderColor = borderColor
      self.borderStyle = borderStyle
      self.borderThickness = borderThickness
      self.cornerRadius = cornerRadius
      super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
      super.draw(dirtyRect)

      let path = CGMutablePath(
        roundedRect: bounds.insetBy(dx: borderThickness, dy: borderThickness),
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil)

      let shapeLayer = CAShapeLayer()

      switch borderStyle {
      case .solid: break
      case .dashed: shapeLayer.lineDashPattern = [4, 4]
      case .noBorder: return
      }

      shapeLayer.lineWidth = borderThickness
      shapeLayer.strokeColor = borderColor.cgColor
      shapeLayer.fillColor = .clear
      shapeLayer.anchorPoint = .zero
      shapeLayer.path = path

      wantsLayer = true
      layer?.addSublayer(shapeLayer)
      layer?.backgroundColor = .clear
    }
  }
}
