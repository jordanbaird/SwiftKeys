//===----------------------------------------------------------------------===//
//
// Storage.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation

class Storage<Value> {
  private let policy: AssociationPolicy

  private var key: UnsafeMutableRawPointer {
    Unmanaged.passUnretained(self).toOpaque()
  }

  init(
    _ type: Value.Type = Value.self,
    _ policy: AssociationPolicy = .retainNonatomic
  ) {
    self.policy = policy
  }

  subscript<Object: AnyObject>(_ object: Object) -> Value? {
    get { objc_getAssociatedObject(object, key) as? Value }
    set { objc_setAssociatedObject(object, key, newValue, policy.objcValue) }
  }
}

extension Storage {
  enum AssociationPolicy {
    case assign
    case copy
    case copyNonatomic
    case retain
    case retainNonatomic

    fileprivate var objcValue: objc_AssociationPolicy {
      switch self {
      case .assign:
        return .OBJC_ASSOCIATION_ASSIGN
      case .copy:
        return .OBJC_ASSOCIATION_COPY
      case .copyNonatomic:
        return .OBJC_ASSOCIATION_COPY_NONATOMIC
      case .retain:
        return .OBJC_ASSOCIATION_RETAIN
      case .retainNonatomic:
        return .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      }
    }
  }
}
