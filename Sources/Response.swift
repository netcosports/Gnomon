//
//  Response.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import SwiftyJSON
import AEXML

public protocol BaseModel {
  static func model(with data: Data, atPath path: String?) throws -> Self
  static func models(with data: Data, atPath path: String?) throws -> [Self]
  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?]
}

public protocol Result {
  associatedtype ModelType: BaseModel
  init(data: Data, atPath path: String?) throws
}

public protocol NonOptionalResult: Result { }

public protocol OptionalResult: Result {
  static func empty() -> Self
}

public protocol Single: Result { }
public protocol Multiple: Result { }

public struct SingleResult<T: BaseModel>: Single, NonOptionalResult {
  public typealias ModelType = T
  public let model: ModelType

  public init(data: Data, atPath path: String?) throws {
    self.model = try T.model(with: data, atPath: path)
  }
}

public struct SingleOptionalResult<T: BaseModel>: Single, OptionalResult {
  public typealias ModelType = T
  public let model: ModelType?

  public init(data: Data, atPath path: String?) {
    do {
      self.model = try T.model(with: data, atPath: path)
    } catch let e {
      self.model = nil
      Gnomon.log("\(e)")
    }
  }

  private init() {
    model = nil
  }

  public static func empty() -> SingleOptionalResult {
    return SingleOptionalResult()
  }
}

public struct MultipleResults<T: BaseModel>: Multiple, NonOptionalResult {
  public typealias ModelType = T
  public let models: [ModelType]

  public init(data: Data, atPath path: String?) throws {
    self.init(models: try T.models(with: data, atPath: path))
  }

  public init(models: [ModelType]) {
    self.models = models
  }
}

public struct MultipleOptionalResults<T: BaseModel>: Multiple, OptionalResult {
  public typealias ModelType = T
  public let models: [ModelType?]

  public init(data: Data, atPath path: String?) {
    do {
      self.init(models: try T.optionalModels(with: data, atPath: path))
    } catch let e {
      Gnomon.log("\(e)")
      self.init(models: [])
    }
  }

  public init(models: [ModelType?]) {
    self.models = models
  }

  public static func empty() -> MultipleOptionalResults {
    return MultipleOptionalResults(models: [])
  }
}

public enum ResponseType {
  case localCache, httpCache, regular
}

public struct Response<ResultType: Result> {

  public let result: ResultType
  public let responseType: ResponseType

}

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
      throw CommonError.unableToParseModel(message: "invalid response or xpath")
    }
    return try Self(xpathed)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let json = JSON(data: data)
    let jsonArray: [JSON]

    if let path = path {
      guard let xpathed = json.xpath(path).array else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = xpathed
    } else {
      guard let array = json.array else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
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
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
      }
      jsonArray = xpathed
    } else {
      guard let array = json.array else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
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
      throw CommonError.unableToParseModel(message: "invalid response or xpath")
    }

    return try Self(xpathed)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    let xml = try AEXMLDocument(xml: data)
    let xmlArray: [AEXMLElement]

    if let path = path {
      let xpathed = xml.xpath(path)
      guard xpathed.error == nil, let all = xpathed.all else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    } else {
      guard let all = xml.root.all else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
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
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
      }
      xmlArray = all
    } else {
      guard let all = xml.root.all else {
        throw CommonError.unableToParseModel(message: "invalid response or xpath")
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

public protocol StringModel: BaseModel {
  init(with string: String)
  static var encoding: String.Encoding { get }
}

public extension StringModel {

  static func model(with data: Data, atPath path: String?) throws -> Self {
    if path != nil {
      Gnomon.log("StringModel doesn't support xpath")
    }

    guard let string = String(data: data, encoding: Self.encoding) else {
      throw "can't parse String from received data"
    }

    return Self(with: string)
  }

  static func models(with data: Data, atPath path: String?) throws -> [Self] {
    throw "StringModel doesn't support multiple models parsing"
  }

  static func optionalModels(with data: Data, atPath path: String?) throws -> [Self?] {
    throw "StringModel doesn't support multiple models parsing"
  }

}

extension String: StringModel {

  public init(with string: String) {
    self = string
  }

  public static var encoding: String.Encoding { return .utf8 }

}
