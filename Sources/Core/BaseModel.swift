//
//  Created by Vladimir Burdukov on 24/02/2018.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import Foundation

public protocol DataContainerIterator {
  associatedtype Element
  var count: Int? { get }
  mutating func next() -> Element?
}

public protocol DataContainerProtocol {
  static func container(with data: Data, at path: String?) throws -> Self

  associatedtype Iterator: DataContainerIterator where Iterator.Element == Self
  func multiple() -> Iterator?

  static func empty() -> Self
}

public protocol BaseModel {
  associatedtype DataContainer: DataContainerProtocol
  static func dataContainer(with data: Data, at path: String?) throws -> DataContainer

  init(_ container: DataContainer) throws
}

extension BaseModel {

  public static func dataContainer(with data: Data, at path: String?) throws -> DataContainer {
    return try DataContainer.container(with: data, at: path)
  }

}

public struct GenericDataContainerIterator<E>: DataContainerIterator {

  private let array: [E]
  private var index = 0

  init(_ array: [E]) {
    self.array = array
  }

  public typealias Element = E

  public mutating func next() -> E? {
    if array.indices.contains(index) {
      defer { index = array.index(after: index) }
      return array[index]
    } else {
      return nil
    }
  }

  public var count: Int? { return array.count }

}

extension Array: BaseModel where Element: BaseModel {

  public typealias DataContainer = Element.DataContainer

  public static func dataContainer(with data: Data, at path: String?) throws -> DataContainer {
    return try Element.dataContainer(with: data, at: path)
  }

  public init(_ container: Element.DataContainer) throws {
    guard var iterator = container.multiple() else {
      throw "instance of \(Element.DataContainer.self) is not iteratable"
    }
    var result = [Element]()
    if let count = iterator.count {
      result.reserveCapacity(count)
    }

    while let container = iterator.next() {
      result.append(try Element.init(container))
    }

    self = result
  }

}

extension Optional: BaseModel where Wrapped: BaseModel {

  public typealias DataContainer = Wrapped.DataContainer

  public static func dataContainer(with data: Data, at path: String?) throws -> DataContainer {
    return (try? Wrapped.dataContainer(with: data, at: path)) ?? DataContainer.empty()
  }

  public init(_ container: DataContainer) throws {
    if let wrapped = try? Wrapped.init(container) {
      self = .some(wrapped)
    } else {
      self = .none
    }
  }

}
