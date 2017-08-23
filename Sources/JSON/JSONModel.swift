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
    let json = JSON(data: data)

    guard let path = path else {
      return try Self(json)
    }

    let xpathed = json.xpath(path)
    guard xpathed.error == nil else {
      throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
    }
    return try Self(xpathed)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let json = JSON(data: data)
    let jsonArray: [JSON]

    if let path = path {
      guard let xpathed = json.xpath(path).array else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = xpathed
    } else {
      guard let array = json.array else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = array
    }

    return try jsonArray.map { try Self($0) }
  }

  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?] {
    let json = JSON(data: data)
    let jsonArray: [JSON]

    if let path = path {
      guard let xpathed = json.xpath(path).array else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = xpathed
    } else {
      guard let array = json.array else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = array
    }

    return jsonArray.map {
      do {
        return try Self($0)
      } catch let e {
        Gnomon.log("\(e)")
        return nil
      }
    }
  }

}

extension JSON {

  func xpath(_ path: String) -> JSON {
    guard path.characters.count > 0 else { return JSON.null }
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return xpath(components)
  }

  private func xpath(_ components: [String]) -> JSON {
    guard let key = components.first else { return self }
    let value = self[key]
    return value.xpath(Array(components.dropFirst()))
  }
  
}
