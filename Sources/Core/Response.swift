//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation

public enum ResponseType {
  case localCache, httpCache, regular
}

public struct Response<Model: BaseModel> {

  @available(*, unavailable, renamed: "result")
  public var model: Model { return result }

  public let result: Model
  public let type: ResponseType
  public let headers: [String: String]
  public let statusCode: Int

  @available(*, unavailable, renamed: "type")
  public var responseType: ResponseType { return type }

}
