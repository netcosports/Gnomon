//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation

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
    } catch {
      self.model = nil
      Gnomon.errorLog("\(error)")
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
    } catch {
      Gnomon.errorLog("\(error)")
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
  public let headers: [String: String]
  public let statusCode: Int

}

public extension Response where ResultType: OptionalResult {

  public static func empty(with responseType: ResponseType) -> Response<ResultType> {
    return Response(result: .empty(), responseType: responseType, headers: [:], statusCode: 200)
  }

}

public protocol StringModel: BaseModel {
  init(with string: String)
  static var encoding: String.Encoding { get }
}

public extension StringModel {

  static func model(with data: Data, atPath path: String?) throws -> Self {
    if path != nil {
      Gnomon.errorLog("StringModel doesn't support xpath")
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
