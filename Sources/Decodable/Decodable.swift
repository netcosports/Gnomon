//
//  Created by Vladimir Burdukov on 27/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
  import Gnomon
#endif

extension CodingUserInfoKey {

  static let xpath = CodingUserInfoKey(rawValue: "Gnomon.XPath")!

}

public protocol DecodableModel: BaseModel, Decodable where DataContainer == DecoderContainer {

  static var decoder: JSONDecoder { get }

}

public extension DecodableModel {

  static var decoder: JSONDecoder { return JSONDecoder() }

    static func dataContainer(with data: Data, at path: String?) throws -> DecoderContainer {
    let decoder = Self.decoder
    decoder.userInfo[.xpath] = path
    return try decoder.decode(DecoderContainer.self, from: data)
  }

    init(_ container: DecoderContainer) throws {
    try self.init(from: container.decoder)
  }

}

private struct EmptyDecoder: Decoder {

  let codingPath: [CodingKey] = []
  let userInfo: [CodingUserInfoKey: Any] = [:]

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    throw "decoder is empty"
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    throw "decoder is empty"
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    throw "decoder is empty"
  }

}

public struct UnkeyedDecodingContainerIterator: DataContainerIterator {

  var unkeyed: UnkeyedDecodingContainer
  init(_ unkeyed: UnkeyedDecodingContainer) {
    self.unkeyed = unkeyed
  }

  public var count: Int? { return unkeyed.count }

  public typealias Element = DecoderContainer

  public mutating func next() -> DecoderContainer? {
    if let decoder = try? unkeyed.superDecoder() {
      return DecoderContainer(decoder)
    } else {
      return nil
    }
  }

}

public struct DecoderContainer: DataContainerProtocol, Decodable {

  let decoder: Decoder
  init(_ decoder: Decoder) {
    self.decoder = decoder
  }

  public init(from decoder: Decoder) throws {
    self.decoder = try decoder.decoder(by: decoder.userInfo[.xpath] as? String)
  }

  public typealias Iterator = UnkeyedDecodingContainerIterator

  public static func container(with data: Data, at path: String?) throws -> DecoderContainer {
    throw "container should be parsed in DecodableModel"
  }

  public func multiple() -> UnkeyedDecodingContainerIterator? {
    guard let unkeyed = try? decoder.unkeyedContainer() else { return nil }
    return UnkeyedDecodingContainerIterator(unkeyed)
  }

  public static func empty() -> DecoderContainer {
    return DecoderContainer(EmptyDecoder())
  }

}
