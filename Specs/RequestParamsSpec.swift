//
//  RequestParamsSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 7/10/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import XCTest
import Nimble

@testable import Gnomon

class ParamsSpec: XCTestCase {

  func testQueryParams() {
    for method in [Method.OPTIONS, .GET, .HEAD, .POST, .PUT, .PATCH, .DELETE, .TRACE, .CONNECT] {
      do {
        let request = try Request<String>(URLString: "https://example.com").setMethod(method)
          .setParams(.query(["key1": "value1", "key2": ["1", "2"]]))
        let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

        expect(urlRequest.url) == URL(string: "https://example.com?key1=value1&key2%5B%5D=1&key2%5B%5D=2")!
      } catch {
        fail("\(error)")
      }
    }
  }

}
