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

  func testMultipleSameType() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }

      guard let responses = try Gnomon.models(for: requests).toBlocking().first() else {
        throw "can't extract responses"
      }

      expect(responses).to(haveCount(3))

      expect(responses[0]).notTo(beNil())
      expect(responses[0]?.result.key) == 123

      expect(responses[1]).notTo(beNil())
      expect(responses[1]?.result.key) == 234

      expect(responses[2]).notTo(beNil())
      expect(responses[2]?.result.key) == 345
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOptionalSameType() {
    do {
      var requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }
      requests.append(try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?failKey=123")
        .setMethod(.GET).setXPath("args").build())

      guard let responses = try Gnomon.models(for: requests).toBlocking().first() else {
        throw "can't extract responses"
      }

      expect(responses).to(haveCount(4))
      expect(responses[0]).notTo(beNil())
      expect(responses[0]?.result.key).to(equal(123))

      expect(responses[1]).notTo(beNil())
      expect(responses[1]?.result.key).to(equal(234))

      expect(responses[2]).notTo(beNil())
      expect(responses[2]?.result.key).to(equal(345))

      expect(responses[3]).to(beNil())
    } catch {
      fail("\(error)")
      return
    }

  }

  func testMultipleOrder() {
    do {
      let requests = [
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/delay/0.3?key=123")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/delay/0.2?key=234")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/delay/0.1?key=345")
          .setMethod(.GET).setXPath("args").build()
      ]

      guard let responses = try Gnomon.models(for: requests).toBlocking().first() else {
        throw "can't extract responses"
      }

      expect(responses).to(haveCount(3))

      expect(responses[0]).notTo(beNil())
      expect(responses[0]?.result.key) == 123

      expect(responses[1]).notTo(beNil())
      expect(responses[1]?.result.key) == 234

      expect(responses[2]).notTo(beNil())
      expect(responses[2]?.result.key) == 345
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleOrderOneFail() {
    do {
      let requests = [
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/delay/0.3?key=123")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/status/404?key=234")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/delay/0.1?key=345")
          .setMethod(.GET).setXPath("args").build()
      ]

      guard let responses = try Gnomon.models(for: requests).toBlocking().first() else {
        throw "can't extract responses"
      }

      expect(responses).to(haveCount(3))

      expect(responses[0]).notTo(beNil())
      expect(responses[0]?.result.key) == 123

      expect(responses[1]).to(beNil())

      expect(responses[2]).notTo(beNil())
      expect(responses[2]?.result.key) == 345
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

  func testMultipleDifferent() {
    do {
      let request1 = try RequestBuilder<TestModel1>()
        .setURLString("\(Params.API.baseURL)/get?key=1")
        .setMethod(.GET).setXPath("args").build()
      let request2 = try RequestBuilder<TestModel2>()
        .setURLString("\(Params.API.baseURL)/get?otherKey=2")
        .setMethod(.GET).setXPath("args").build()

      let responses = try Observable.zip(
        Gnomon.models(for: request1),
        Gnomon.models(for: request2)
      ).toBlocking().first()

      expect(responses).toNot(beNil())

      guard let result1 = responses?.0, let result2 = responses?.1 else {
        throw "can't extract responses"
      }

      expect(result1.result.key).to(equal(1))
      expect(result2.result.otherKey).to(equal(2))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleDifferentOneFail() {
    do {
      let request1 = try RequestBuilder<TestModel1>()
        .setURLString("\(Params.API.baseURL)/get?key=1")
        .setMethod(.GET).setXPath("args").build()
      let request2 = try RequestBuilder<TestModel2>()
        .setURLString("\(Params.API.baseURL)/get?failKey=2")
        .setMethod(.GET).setXPath("args").build()

      guard let responses = try Observable.zip(
        Gnomon.models(for: request1),
        Gnomon.models(for: request2).map { Optional.some($0) }.catchErrorJustReturn(nil)
      ).toBlocking().first() else {
        throw "can't extract responses"
      }

      expect(responses.0.result.key).to(equal(1))
      expect(responses.1).to(beNil())
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleEmptyArray() {
    do {
      let requests = [Request<TestModel1?>]()
      let optionalRequests = [Request<TestModel1?>]()

      expect(try Gnomon.cachedModels(for: optionalRequests).toBlocking().first()).to(haveCount(0))
      expect(try Gnomon.models(for: optionalRequests).toBlocking().first()).to(haveCount(0))
      expect(try Gnomon.models(for: requests).toBlocking().first()).to(haveCount(0))

      let cachedThenFetch = try Gnomon.cachedThenFetch(optionalRequests).toBlocking().toArray()
      expect(cachedThenFetch).to(haveCount(2))
      expect(cachedThenFetch[0]).to(haveCount(0))
      expect(cachedThenFetch[1]).to(haveCount(0))
    } catch {
      fail("\(error)")
      return
    }
  }

}
