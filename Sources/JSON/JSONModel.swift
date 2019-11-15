//
//  Created by Vladimir Burdukov on 08/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Foundation
import SwiftyJSON
#if SWIFT_PACKAGE
  import Gnomon
#endif

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

public protocol JSONModel: BaseModel where DataContainer == JSON {
}

extension JSON: DataContainerProtocol {

  public typealias Iterator = GenericDataContainerIterator<JSON>

  public static func container(with data: Data, at path: String?) throws -> JSON {
    let json = try JSON(data: data)

    if let path = path {
      let xpathed = try json.xpath(path)
      if let error = xpathed.error {
        throw Gnomon.Error.unableToParseModel(error)
      }

      return xpathed
    } else {
      return json
    }
  }

  public func multiple() -> GenericDataContainerIterator<JSON>? {
    if let array = array {
      return .init(array)
    } else {
      return nil
    }
  }

  public static func empty() -> JSON {
    return JSON()
  }

}
