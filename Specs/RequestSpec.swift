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

let BlockingTimeout: RxTimeInterval = 0.5

class RequestSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    URLCache.shared.removeAllCachedResponses()
    Gnomon.removeAllInterceptors()
  }

  func testSingleRequest() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result.key) == 123
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testSingleOptionalSuccessfulRequest() {
    do {
      let request = try Request<TestModel1?>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result?.key) == 123
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testSingleOptionalFailedRequest() {
    do {
      let request = try Request<TestModel1?>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["invalid": 123], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.statusCode) == 200
        expect(response.result).to(beNil())
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testArrayRequest() {
    do {
      let request = try Request<[TestModel1]>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        ["key": 123],
        ["key": 234],
        ["key": 345]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0].key).to(equal(123))
        expect(response.result[1].key).to(equal(234))
        expect(response.result[2].key).to(equal(345))
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testOptionalArraySuccessfulRequest() {
    do {
      let request = try Request<[TestModel1]?>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        ["key": 123],
        ["key": 234],
        ["key": 345]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result?[0].key).to(equal(123))
        expect(response.result?[1].key).to(equal(234))
        expect(response.result?[2].key).to(equal(345))
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testOptionalArrayFailedRequest() {
    do {
      let request = try Request<[TestModel1]?>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["invalid": "type"], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(beNil())
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testArrayOfOptionalsSuccessfulRequest() {
    do {
      let request = try Request<[TestModel1?]>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        ["key": 123],
        ["key": 234],
        ["key": 345]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0]?.key).to(equal(123))
        expect(response.result[1]?.key).to(equal(234))
        expect(response.result[2]?.key).to(equal(345))
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testArrayOfOptionalsFailedRequest() {
    do {
      let request = try Request<[TestModel1?]>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        ["key": 123],
        ["_key": 234],
        ["key": 345]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]

        expect(response.result).to(haveCount(3))
        expect(response.result[0]?.key).to(equal(123))
        expect(response.result[1]).to(beNil())
        expect(response.result[2]?.key).to(equal(345))
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

  func testStringRequest() {
    do {
      let request = try Request<String>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.stringResponse(result: "test string", cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let response = responses[0]
        expect(response.result) == "test string"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testErrorStatusCode() {
    do {
      let request = try Request<String>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.stringResponse(result: "error string", statusCode: 401, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case .completed:
        fail("request should fail")
      case let .failed(_, Gnomon.Error.errorStatusCode(401, data)):
        expect(String(data: data, encoding: .utf8)) == "error string"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
    }
  }

}
