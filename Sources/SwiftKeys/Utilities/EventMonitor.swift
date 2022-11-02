//===----------------------------------------------------------------------===//
//
// EventMonitor.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

struct EventMonitor {
  private var monitor: Any?
  private var mask: NSEvent.EventTypeMask
  private var handler: (NSEvent) -> NSEvent?
  
  init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
    self.mask = mask
    self.handler = handler
  }
  
  mutating func start() {
    guard monitor == nil else {
      return
    }
    monitor = NSEvent.addLocalMonitorForEvents(
      matching: mask,
      handler: handler)
  }
  
  mutating func stop() {
    guard monitor != nil else {
      return
    }
    NSEvent.removeMonitor(monitor as Any)
    monitor = nil
  }
}
