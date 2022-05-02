//===----------------------------------------------------------------------===//
//
// ProxyStorage.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

/// A storage container for instances of `EventProxy`.
///
/// This type can store and retrieve a proxy based on either its identifier
/// or its name. Both are valid methods of retrieval, making it possible for
/// both `KeyEvent` and `EventProxy` to use the same backing storage (`KeyEvent`
/// only has access to the name, while `EventProxy`, in certain cases, only
/// has access to the identifier).
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
  
  /// Retrieves the proxy with the given identifier.
  static func proxy(with identifier: UInt32) -> EventProxy? {
    all.first { $0.identifier == identifier }?.proxy
  }
  
  /// Retrieves the proxy with the given name.
  static func proxy(with name: KeyEvent.Name) -> EventProxy? {
    all.first { $0.name == name }?.proxy
  }
  
  /// Stores the given proxy.
  static func store(_ proxy: EventProxy) {
    all.update(with: .init(proxy))
  }
  
  /// Removes the given proxy from storage.
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
  
  /// Returns a Boolean value that indicates whether the given `ProxyStorage`
  /// instance contains the given `EventProxy`.
  ///
  /// Note that this operator does not simply check for the proxy using the
  /// `===` operator. As `ProxyStorage` uses the proxy's identifier and name
  /// for its `Hashable` and `Equatable` conformances, to ensure consistency,
  /// this operator does the same.
  static func ~= (lhs: Self, rhs: EventProxy) -> Bool {
    lhs.identifier == rhs.identifier.id &&
    lhs.name == rhs.name
  }
}
