//
//  Created by Vladimir Burdukov on 08/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import AEXML

public protocol XMLModel: BaseModel {
  init(_ xml: AEXMLElement) throws
}

public extension XMLModel {

  static func model(with data: Data, atPath path: String?) throws -> Self {
    let xml = try AEXMLDocument(xml: data)

    guard let path = path else {
      return try Self(xml.root)
    }

    let xpathed = xml.xpath(path)

    guard xpathed.error == nil else {
      throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
    }

    return try Self(xpathed)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let xml = try AEXMLDocument(xml: data)
    let xmlArray: [AEXMLElement]

    if let path = path {
      let xpathed = xml.xpath(path)
      guard xpathed.error == nil, let all = xpathed.all else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    } else {
      guard let all = xml.root.all else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    }

    return try xmlArray.map { try Self($0) }
  }

  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?] {
    let xml = try AEXMLDocument(xml: data)
    let xmlArray: [AEXMLElement]

    if let path = path {
      let xpathed = xml.xpath(path)
      guard xpathed.error == nil, let all = xpathed.all else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    } else {
      guard let all = xml.root.all else {
        throw Gnomon.Error.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    }

    return xmlArray.map {
      do {
        return try Self($0)
      } catch let e {
        Gnomon.log("\(e)")
        return nil
      }
    }
  }

}

extension AEXMLElement {

  func xpath(_ path: String) -> AEXMLElement {
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return xpath(components)
  }

  private func xpath(_ components: [String]) -> AEXMLElement {
    guard let key = components.first else { return self }
    let value = self[key]
    return value.xpath(Array(components.dropFirst()))
  }
  
}
