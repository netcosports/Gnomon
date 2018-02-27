//
//  RequestSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 7/6/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking
import SwiftyJSON

@testable import Gnomon

class RequestSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
    Gnomon.removeAllInterceptors()
  }

  func testPlainSingleRequest() {
    do {
      let request = try RequestBuilder<TestModel5>().setURLString("\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response?.statusCode) == 200
      expect(response?.headers.count) != 0

      guard let result = response?.result else { throw "can't extract response" }

      expect(result.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testPlainMultipleRequest() {
    do {
      let request = try RequestBuilder<[TestModel1]>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array").build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result[0].key).to(equal(123))
      expect(result[1].key).to(equal(234))
      expect(result[2].key).to(equal(345))
    } catch {
      fail("\(error)")
    }
  }

  func testSingleGETWithParamsRequest() {
    do {
      let request = try RequestBuilder<TestModel3>()
        .setURLString("\(Params.API.baseURL)/get?key1=123").setMethod(.GET)
        .setParams(["key2": "234", "key3": [345, 456]]).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.key1).to(equal(123))
      expect(result.key2).to(equal(234))
      expect(result.keys).to(equal([345, 456]))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithParamsRequest() {
    do {
      let request = try RequestBuilder<TestModel4>().setURLString("\(Params.API.baseURL)/post?key1=123")
        .setMethod(.POST).setParams(["key2": "234"]).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.key1).to(equal(123))
      expect(result.key2).to(equal(234))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithJSONParamsRequest() {
    do {
      let request: Request<TestModel6> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.json(["key": "123"])).setXPath("json").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.key).to(equal(123))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithMixedParamsRequest() {
    do {
      let request: Request<TestModel7> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post?key1=123").setMethod(.POST)
        .setParams(.json(["key2": "234"])).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.key1).to(equal(123))
      expect(result.key2).to(equal(234))
    } catch {
      fail("\(error)")
      return
    }
  }
// TODO:
//  func testStringRequest() {
//    do {
//      let request = try RequestBuilder<String>()
//        .setURLString("\(Params.API.baseURL)/robots.txt").setMethod(.GET).build()
//      let response = try Gnomon.models(for: request).toBlocking().first()
//      expect(response).toNot(beNil())
//
//      guard let result = response?.result else {
//        throw "can't extract response"
//      }
//
//      expect(result.model).to(equal("User-agent: *\nDisallow: /deny\n"))
//    } catch {
//      fail("\(error)")
//      return
//    }
//  }

  func testSingleOptionalSuccessfulRequest() {
    do {
      let request = try RequestBuilder<TestModel5?>().setURLString("\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET).build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }

      expect(response.result).toNot(beNil())
      expect(response.result?.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testSingleOptionalFailedRequest() {
    do {
      let request = try RequestBuilder<TestModel5?>().setURLString("\(Params.API.baseURL)/get?invalid=123")
        .setMethod(.GET).build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }
      expect(response.result).to(beNil())
    } catch {
      fail("\(error)")
    }
  }

  func testErrorStatusCode() {
    do {
      let request = try RequestBuilder<TestModel1>()
        .setURLString("\(Params.API.baseURL)/status/403").setMethod(.GET).build()

      _ = try Gnomon.models(for: request).toBlocking().first()
    } catch let e {
      switch e {
      case Gnomon.Error.errorStatusCode(let code, _):
        expect(code) == 403
      default:
        fail("\(e)")
      }

      return
    }

    fail("request should fail")
  }

  func testPublicAccessToRequestBuilderRequest() {
    do {
      let builder = RequestBuilder<TestModel5>().setURLString("\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET)
      _ = builder.request.headers
      _ = try builder.build()
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCustomDataRequest() {
    do {
      guard let url = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "png") else {
        return fail("can't find test file")
      }

      let data = try Data(contentsOf: url)

      let request: Request<DataModel> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.data(data, contentType: "image/png")).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.data) == data
    } catch {
      fail("\(error)")
      return
    }
  }

  func testTimeoutSuccess() {
    do {
      let request = try RequestBuilder<TestModel5>().setURLString("\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET).setTimeout(5).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testTimeoutFail() {
    do {
      let request = try RequestBuilder<TestModel5>().setURLString("\(Params.API.baseURL)/delay/2?key=123")
        .setMethod(.GET).setTimeout(1).build()

      _ = try Gnomon.models(for: request).toBlocking().first()
    } catch {
      expect(error).to(beAKindOf(NSError.self))

      let nsError = error as NSError
      expect(nsError.domain) == NSURLErrorDomain
      expect(nsError.code) == NSURLErrorTimedOut
    }
  }

}
