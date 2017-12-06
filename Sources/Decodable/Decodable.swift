//
//  Created by Vladimir Burdukov on 27/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

extension CodingUserInfoKey {

  static let xpath = CodingUserInfoKey(rawValue: "Gnomon.XPath")!

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
