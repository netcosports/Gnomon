//
//  BoolModel.swift
//  Gnomon
//
//  Created by Sergei Mikhan on 3/16/20.
//

import Foundation

public protocol BoolModel: BaseModel where DataContainer == Bool {
  static var encoding: String.Encoding { get }
}

extension BoolModel {

  public static func dataContainer(with data: Data, at path: String?) throws -> Bool {
    guard let value = String(data: data, encoding: encoding)?.lowercased() else {
      throw "can't parse String with encoding \(encoding)"
    }
    return value == "true" || value == "1"
  }
}

extension Bool: DataContainerProtocol {

  public typealias Iterator = GenericDataContainerIterator<Bool>

  public static func container(with data: Data, at path: String?) throws -> Bool {
    throw "should be implemented in BoolModel"
  }

  public func multiple() -> GenericDataContainerIterator<Bool>? {
    return nil
  }

  public static func empty() -> Bool {
    return false
  }

}

extension Bool: BoolModel {
  public static var encoding: String.Encoding { return .utf8 }
}
