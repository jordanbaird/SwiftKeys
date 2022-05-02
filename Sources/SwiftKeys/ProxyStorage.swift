//===----------------------------------------------------------------------===//
//
// ProxyStorage.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

struct ProxyStorage: Hashable {
  private static var all = Set<Self>()
  
  private let proxy: EventProxy
  
  private var identifier: UInt32 {
    proxy.identifier.id
  }
  
  private var name: KeyEvent.Name {
    proxy.name
  }
  
  private init(_ proxy: EventProxy) {
    self.proxy = proxy
  }
  
  static func proxy(with identifier: UInt32) -> EventProxy? {
    all.first { $0.identifier == identifier }?.proxy
  }
  
  static func proxy(with name: KeyEvent.Name) -> EventProxy? {
    all.first { $0.name == name }?.proxy
  }
  
  static func store(_ proxy: EventProxy) {
    all.update(with: .init(proxy))
  }
  
  static func remove(_ proxy: EventProxy) {
    if let storage = all.first(where: { $0 ~= proxy }) {
      all.remove(storage)
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
    hasher.combine(name)
  }
  
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier &&
    lhs.name == rhs.name
  }
  
  static func ~= (lhs: Self, rhs: EventProxy) -> Bool {
    lhs.identifier == rhs.identifier.id &&
    lhs.name == rhs.name
  }
}
