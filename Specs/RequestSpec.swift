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
      let request = try Request<TestModel5>(URLString: "\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET)

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response?.statusCode) == 200
      expect(response?.headers.count) != 0

      guard let result = response?.result else { throw "can't extract response" }

      expect(result.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testSingleOptionalSuccessfulRequest() {
    do {
      let request = try Request<TestModel5?>(URLString: "\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET)

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }

      expect(response.result).toNot(beNil())
      expect(response.result?.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testSingleOptionalFailedRequest() {
    do {
      let request = try Request<TestModel5?>(URLString: "\(Params.API.baseURL)/get?invalid=123")
        .setMethod(.GET)

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }
      expect(response.result).to(beNil())
    } catch {
      fail("\(error)")
    }
  }

  func testArrayRequest() {
    do {
      let request = try Request<[TestModel1]>(URLString: "\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array")

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result[0].key).to(equal(123))
      expect(result[1].key).to(equal(234))
      expect(result[2].key).to(equal(345))
    } catch {
      fail("\(error)")
    }
  }

  func testOptionalArraySuccessfulRequest() {
    do {
      let request = try Request<[TestModel1]?>(URLString: "\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array")

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }

      expect(response.result).notTo(beNil())

      expect(response.result?.count) == 3
      expect(response.result?[0].key) == 123
      expect(response.result?[1].key) == 234
      expect(response.result?[2].key) == 345
    } catch {
      fail("\(error)")
    }
  }

  func testOptionalArrayFailedRequest() {
    do {
      let request = try Request<[TestModel1]?>(URLString: "\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["_": []])).setXPath("json/array")

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }
      expect(response.result).to(beNil())
    } catch {
      fail("\(error)")
    }
  }

  func testArrayOfOptionalsSuccessfulRequest() {
    do {
      let request = try Request<[TestModel1?]>(URLString: "\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array")

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }

      expect(response.result.count) == 3
      expect(response.result[0]?.key) == 123
      expect(response.result[1]?.key) == 234
      expect(response.result[2]?.key) == 345
    } catch {
      fail("\(error)")
    }
  }

  func testArrayOfOptionalsFailedRequest() {
    do {
      let request = try Request<[TestModel1?]>(URLString: "\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["_key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array")

      guard let response = try Gnomon.models(for: request).toBlocking().first() else { throw "can't extract response" }

      expect(response.result.count) == 3
      expect(response.result[0]?.key) == 123
      expect(response.result[1]).to(beNil())
      expect(response.result[2]?.key) == 345
    } catch {
      fail("\(error)")
    }
  }

  func testSingleGETWithParamsRequest() {
    do {
      let request = try Request<TestModel3>(URLString: "\(Params.API.baseURL)/get?key1=123").setMethod(.GET)
        .setParams(["key2": "234", "key3": [345, 456]])

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
      let request = try Request<TestModel4>(URLString: "\(Params.API.baseURL)/post?key1=123")
        .setMethod(.POST).setParams(["key2": "234"])

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
      let request = try Request<TestModel6>(URLString: "\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.json(["key": "123"])).setXPath("json")

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
      let request = try Request<TestModel7>(URLString: "\(Params.API.baseURL)/post?key1=123").setMethod(.POST)
        .setParams(.json(["key2": "234"]))

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

  func testStringRequest() {
    do {
      let request = try Request<String>(URLString: "\(Params.API.baseURL)/robots.txt").setMethod(.GET)

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        throw "can't extract response"
      }

      expect(response.result).to(equal("User-agent: *\nDisallow: /deny\n"))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testErrorStatusCode() {
    do {
      let request = try Request<TestModel1>(URLString: "\(Params.API.baseURL)/status/403").setMethod(.GET)

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

  func testCustomDataRequest() {
    do {
      guard let url = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "png") else {
        return fail("can't find test file")
      }

      let data = try Data(contentsOf: url)

      let request = try Request<DataModel>(URLString: "\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.data(data, contentType: "image/png"))

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
      let request = try Request<TestModel5>(URLString: "\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET).setTimeout(5)

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testTimeoutFail() {
    do {
      let request = try Request<TestModel5>(URLString: "\(Params.API.baseURL)/delay/2?key=123")
        .setMethod(.GET).setTimeout(1)

      _ = try Gnomon.models(for: request).toBlocking().first()
    } catch {
      expect(error).to(beAKindOf(NSError.self))

      let nsError = error as NSError
      expect(nsError.domain) == NSURLErrorDomain
      expect(nsError.code) == NSURLErrorTimedOut
    }
  }

}
