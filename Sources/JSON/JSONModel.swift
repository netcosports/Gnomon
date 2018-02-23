//
//  Created by Vladimir Burdukov on 08/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import SwiftyJSON

public protocol JSONModel: BaseModel {
  init(_ json: JSON) throws
}

public extension JSONModel {

  static func model(with data: Data, atPath path: String?) throws -> Self {
    let json = try JSON(data: data)

    guard let path = path else {
      return try Self(json)
    }

    let xpathed = try json.xpath(path)
    if let error = xpathed.error {
      throw Gnomon.Error.unableToParseModel(error)
    }
    return try Self(xpathed)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let json = try JSON(data: data)
    let jsonArray: [JSON]

    if let error = json.error {
      throw Gnomon.Error.unableToParseModel(error)
    }

    if json.null != nil {
      throw Gnomon.Error.unableToParseModel("expected dictionary or array, received null")
    }

    if let path = path {
      let xpathed = try json.xpath(path)
      if let error = xpathed.error {
        throw Gnomon.Error.unableToParseModel(error)
      } else if xpathed.null != nil {
        throw Gnomon.Error.unableToParseModel("expected dictionary or array, received null")
      }

      if let array = xpathed.array {
        jsonArray = array
      } else {
        jsonArray = [xpathed]
      }
    } else {
      if let array = json.array {
        jsonArray = array
      } else {
        jsonArray = [json]
      }
    }

    return try jsonArray.map { try Self($0) }
  }

  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?] {
    let json = try JSON(data: data)
    let jsonArray: [JSON]

    if let error = json.error {
      throw Gnomon.Error.unableToParseModel(error)
    }

    if json.null != nil {
      throw Gnomon.Error.unableToParseModel("expected dictionary or array, received null")
    }

    if let path = path {
      let xpathed = try json.xpath(path)
      if let error = xpathed.error {
        throw Gnomon.Error.unableToParseModel(error)
      } else if xpathed.null != nil {
        throw Gnomon.Error.unableToParseModel("expected dictionary or array, received null")
      }

      if let array = xpathed.array {
        jsonArray = array
      } else {
        jsonArray = [xpathed]
      }
    } else {
      if let array = json.array {
        jsonArray = array
      } else {
        jsonArray = [json]
      }
    }

    return jsonArray.map {
      do {
        return try Self($0)
      } catch {
        Gnomon.errorLog("\(error)")
        return nil
      }
    }
  }

}

extension JSON {

  func xpath(_ path: String) throws -> JSON {
    guard path.count > 0 else { throw "empty xpath" }
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return try xpath(components)
  }

  private func xpath(_ components: [String]) throws -> JSON {
    guard let key = components.first else { return self }
    let value = self[key]
    guard value.exists() else {
      throw "can't find key \(key) in json \(self)"
    }
    return try value.xpath(Array(components.dropFirst()))
  }

}
