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
      let request = try RequestBuilder<SingleResult<TestModel5>>().setURLString("\(Params.API.baseURL)/get?key=123")
        .setMethod(.GET).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.model.key).to(equal(123))
    } catch {
      fail("\(error)")
    }
  }

  func testPlainMultipleRequest() {
    do {
      let request = try RequestBuilder<MultipleResults<TestModel1>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array").build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.models[0].key).to(equal(123))
      expect(result.models[1].key).to(equal(234))
      expect(result.models[2].key).to(equal(345))
    } catch {
      fail("\(error)")
    }
  }

  func testPlainSingleOptionalRequest() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.model).notTo(beNil())
      expect(result.model?.key).to(equal(123))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainMultipleOptionalRequest() {
    do {
      let request = try RequestBuilder<MultipleOptionalResults<TestModel1>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(["array": [
          ["key": "123"],
          ["key": "234"],
          ["key": "345"]
        ]])).setXPath("json/array").build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result, result.models.count != 0 else { throw "can't extract response" }

      expect(result.models[0]?.key).to(equal(123))
      expect(result.models[1]?.key).to(equal(234))
      expect(result.models[2]?.key).to(equal(345))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleGETWithParamsRequest() {
    do {
      let request = try RequestBuilder<SingleResult<TestModel3>>()
        .setURLString("\(Params.API.baseURL)/get?key1=123").setMethod(.GET)
        .setParams(["key2": "234", "key3": [345, 456]]).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.model.key1).to(equal(123))
      expect(result.model.key2).to(equal(234))
      expect(result.model.keys).to(equal([345, 456]))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithParamsRequest() {
    do {
      let request = try RequestBuilder<SingleResult<TestModel4>>().setURLString("\(Params.API.baseURL)/post?key1=123")
        .setMethod(.POST).setParams(["key2": "234"]).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.key1).to(equal(123))
      expect(result.model.key2).to(equal(234))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithJSONParamsRequest() {
    do {
      let request: Request<SingleResult<TestModel6>> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.json(["key": "123"])).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.key).to(equal(123))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainSinglePOSTWithMixedParamsRequest() {
    do {
      let request: Request<SingleResult<TestModel7>> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post?key1=123").setMethod(.POST)
        .setParams(.json(["key2": "234"])).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.model.key1).to(equal(123))
      expect(result.model.key2).to(equal(234))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testStringRequest() {
    do {
      let request = try RequestBuilder<SingleResult<String>>()
        .setURLString("\(Params.API.baseURL)/robots.txt").setMethod(.GET).build()
      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model).to(equal("User-agent: *\nDisallow: /deny\n"))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testErrorStatusCode() {
    do {
      let request = try RequestBuilder<SingleResult<TestModel1>>()
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

  func testCastSingleDictionaryToMultipleResults() {
    do {
      let request: Request<MultipleResults<TestModel6>> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.json(["key": "123"])).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.models).to(haveCount(1))
      expect(result.models[0].key) == 123
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCastSingleDictionaryToMultipleOptionalResults() {
    do {
      let request: Request<MultipleOptionalResults<TestModel6>> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.json(["key": "123"])).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.models).to(haveCount(1))
      expect(result.models[0]?.key) == 123
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPublicAccessToRequestBuilderRequest() {
    do {
      let builder = RequestBuilder<SingleResult<TestModel5>>().setURLString("\(Params.API.baseURL)/get?key=123")
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

      let request: Request<SingleResult<DataModel>> = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.data(data, contentType: "image/png")).build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.data) == data
    } catch {
      fail("\(error)")
      return
    }
  }

}
