//
//  Created by Vladimir Burdukov on 27/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

extension CodingUserInfoKey {

  static let xpath = CodingUserInfoKey(rawValue: "Gnomon.XPath")!

}

private struct _XPathKey: CodingKey {

  let components: [String]

  init(key: String) {
    self.init(with: key.components(separatedBy: "/"))
  }

  init(with components: [String]) {
    self.components = components
  }

  var next: _XPathKey {
    var components = self.components
    _ = components.removeFirst()
    return _XPathKey(with: components)
  }

  var stringValue: String {
    return components[0]
  }

  init?(stringValue: String) {
    self.init(key: stringValue)
  }

  var intValue: Int?
  init?(intValue: Int) {
    return nil
  }

}

private extension Decoder {

  func decoder(by xpath: String?) throws -> Decoder {
    guard let xpath = xpath else { return self }

    var container = try self.container(keyedBy: _XPathKey.self)
    var key = _XPathKey(key: xpath)
    while key.components.count > 1 {
      container = try container.nestedContainer(keyedBy: _XPathKey.self, forKey: key)
      key = key.next
    }

    return try container.superDecoder(forKey: key)
  }

}

private struct _Single<T: Decodable & BaseModel>: Decodable {

  let model: T

  init(from decoder: Decoder) throws {
    let decoder = try decoder.decoder(by: decoder.userInfo[.xpath] as? String)
    model = try T(from: decoder)
  }

}

private struct _Multiple<T: Decodable & BaseModel>: Decodable {

  let models: [T]

  init(from decoder: Decoder) throws {
    let decoder = try decoder.decoder(by: decoder.userInfo[.xpath] as? String)
    var unkeyed = try decoder.unkeyedContainer()

    var models: [T] = []

    while !unkeyed.isAtEnd {
      models.append(try T(from: unkeyed.superDecoder()))
    }

    self.models = models
  }

}

private struct _MultipleOptional<T: Decodable & BaseModel>: Decodable {

  let models: [T?]

  init(from decoder: Decoder) throws {
    let decoder = try decoder.decoder(by: decoder.userInfo[.xpath] as? String)
    var unkeyed = try decoder.unkeyedContainer()

    var models: [T?] = []

    while !unkeyed.isAtEnd {
      models.append(try? T(from: unkeyed.superDecoder()))
    }

    self.models = models
  }

}

public protocol DecodableModel: BaseModel, Decodable {

  static var decoder: JSONDecoder { get }

}

public extension DecodableModel {

  static var decoder: JSONDecoder { return JSONDecoder() }

}

public extension DecodableModel {

  static func model(with data: Data, atPath path: String?) throws -> Self {
    let decoder = Self.decoder
    decoder.userInfo[.xpath] = path
    let container = try decoder.decode(_Single<Self>.self, from: data)
    return container.model
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let decoder = Self.decoder
    decoder.userInfo[.xpath] = path
    let container = try decoder.decode(_Multiple<Self>.self, from: data)
    return container.models
  }

  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?] {
    let decoder = Self.decoder
    decoder.userInfo[.xpath] = path
    let container = try decoder.decode(_MultipleOptional<Self>.self, from: data)
    return container.models
  }

}
