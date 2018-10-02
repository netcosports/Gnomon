//
//  MultipleRequestsSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 8/4/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import Gnomon

// swiftlint:disable type_body_length

class MultipleRequestsSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testMultiple() {
    do {
      let requests = try [0, 1].map { value -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                           cached: false)
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case let .ok(response):
          expect(response.result.key) == 123
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case let .ok(response):
          expect(response.result.key) == 234
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOneFail() {
    do {
      let requests = try [0, 1].map { value -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        if value == 1 {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                             cached: false)
        } else {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["_key": 123 + 111 * value],
                                                                             cached: false)
        }
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case .ok: fail("request should fail")
        case let .error(Gnomon.Error.unableToParseModel(message as String)):
          expect(message) == "<key> value is invalid = <null>"
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case let .ok(response):
          expect(response.result.key) == 234
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOptional() {
    do {
      let requests = try [0, 1].map { value -> Request<TestModel1?> in
        let request = try Request<TestModel1?>(URLString: "https://example.com")
        request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                           cached: false)
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case let .ok(response):
          expect(response.result?.key) == 123
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case let .ok(response):
          expect(response.result?.key) == 234
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOptionalOneFail() {
    do {
      let requests = try [0, 1].map { value -> Request<TestModel1?> in
        let request = try Request<TestModel1?>(URLString: "https://example.com")
        if value == 1 {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                             cached: false)
        } else {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["_key": 123 + 111 * value],
                                                                             cached: false)
        }
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(2))

        switch results[0] {
        case let .ok(response):
          expect(response.result).to(beNil())
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case let .ok(response):
          expect(response.result?.key) == 234
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOrder() {
    do {
      let requests = try [0, 1, 2].map { value -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                           cached: false,
                                                                           delay: 0.4 - Double(value) * 0.1)
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: 1).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        switch results[0] {
        case let .ok(response):
          expect(response.result.key) == 123
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case let .ok(response):
          expect(response.result.key) == 234
        case let .error(error): fail("\(error)")
        }

        switch results[2] {
        case let .ok(response):
          expect(response.result.key) == 345
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOrderOneFail() {
    do {
      let requests = try [0, 1, 2].map { value -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        if value == 1 {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["invalid": "key"],
                                                                             statusCode: 404, cached: false,
                                                                             delay: 0.4 - Double(value) * 0.1)
        } else {
          request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123 + 111 * value],
                                                                             cached: false,
                                                                             delay: 0.4 - Double(value) * 0.1)
        }
        return request
      }

      let result = Gnomon.models(for: requests).toBlocking(timeout: 1).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        switch results[0] {
        case let .ok(response):
          expect(response.result.key) == 123
        case let .error(error): fail("\(error)")
        }

        switch results[1] {
        case .ok: fail("request should fail")
        case let .error(Gnomon.Error.errorStatusCode(code, _)): expect(code) == 404
        case let .error(error): fail("\(error)")
        }

        switch results[2] {
        case let .ok(response):
          expect(response.result.key) == 345
        case let .error(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      switch error {
      case Gnomon.Error.errorStatusCode(let code, let data):
        expect(code).to(equal(404))
        expect(data).toNot(beNil())
      default: fail("should't fail with other type of error")
      }
      return
    }
  }

  func testMultipleEmptyArray() {
    do {
      let requests = [Request<TestModel1>]()
      let optionalRequests = [Request<TestModel1?>]()

      expect(try Gnomon.cachedModels(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(
        haveCount(0))
      expect(try Gnomon.models(for: optionalRequests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))
      expect(try Gnomon.models(for: requests).toBlocking(timeout: BlockingTimeout).first()).to(haveCount(0))

      let cachedThenFetch = try Gnomon.cachedThenFetch(optionalRequests).toBlocking(timeout: BlockingTimeout).toArray()
      expect(cachedThenFetch).to(haveCount(1))
      expect(cachedThenFetch[0]).to(haveCount(0))
    } catch {
      fail("\(error)")
      return
    }
  }

}
