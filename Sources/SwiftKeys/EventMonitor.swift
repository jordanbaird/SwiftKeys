//===----------------------------------------------------------------------===//
//
// EventMonitor.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

struct EventMonitor {
  var handler: (NSEvent) -> NSEvent?
  
  var mask: NSEvent.EventTypeMask
  
  var monitor: Any?
  
  init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
    self.handler = handler
    self.mask = mask
  }
  
  mutating func start() {
    guard monitor == nil else { return }
    monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
  }
  
  mutating func stop() {
    guard monitor != nil else { return }
    NSEvent.removeMonitor(monitor as Any)
    monitor = nil
  }
}
