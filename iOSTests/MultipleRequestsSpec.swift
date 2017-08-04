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

// swiftlint:disable type_body_length file_length

class MultipleRequestsSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testMultipleEqual() {
    let requests: [Request<SingleResult<TestModel1>>]

    do {
      requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleResult<TestModel1>>]?
    do {
      responses = try Gnomon.models(for: requests).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let results = responses?.map({ $0.result }) else {
      fail("can't extract responses")
      return
    }

    expect(results).to(haveCount(3))
    expect(results[0].model.key).to(equal(123))
    expect(results[1].model.key).to(equal(234))
    expect(results[2].model.key).to(equal(345))
  }

  func testMultipleOptionalEqual() {
    var requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }
      requests.append(try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?failKey=123")
        .setMethod(.GET).setXPath("args").build())
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responses = try Gnomon.models(for: requests).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let results = responses?.map({ $0.result }) else {
      fail("can't extract responses")
      return
    }

    expect(results).to(haveCount(4))
    expect(results[0].model?.key).to(equal(123))
    expect(results[1].model?.key).to(equal(234))
    expect(results[2].model?.key).to(equal(345))
    expect(results[3].model).to(beNil())
  }

  func testMultipleOrder() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = [
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.3?key=123")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.2?key=234")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.1?key=345")
          .setMethod(.GET).setXPath("args").build()
      ]
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responses = try Gnomon.models(for: requests).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let results = responses?.map({ $0.result }) else {
      fail("can't extract responses")
      return
    }

    expect(results).to(haveCount(3))
    expect(results[0].model?.key).to(equal(123))
    expect(results[1].model?.key).to(equal(234))
    expect(results[2].model?.key).to(equal(345))
  }

  func testMultipleOrderOneFail() {
    let requests: [Request<SingleResult<TestModel1>>]

    do {
      requests = [
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.3?key=123")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/status/404?key=234")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.1?key=345")
          .setMethod(.GET).setXPath("args").build()
      ]
    } catch let error {
      fail("\(error)")
      return
    }
    do {
      _ = try Gnomon.models(for: requests).toBlocking().first()
      fail("should fail here")
    } catch {
      switch error {
      case CommonError.errorStatusCode(let code, let data):
        expect(code).to(equal(404))
        expect(data).toNot(beNil())
      default: fail("should't fail with other type of error")
      }
      return
    }
  }

  func testMultipleOrderOfOptionalsOneFail() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = [
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.3?key=123")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/status/404?key=234")
          .setMethod(.GET).setXPath("args").build(),
        try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/delay/0.1?key=345")
          .setMethod(.GET).setXPath("args").build()
      ]
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responses = try Gnomon.models(for: requests).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let results = responses?.map({ $0.result }) else {
      fail("can't extract responses")
      return
    }

    expect(results).to(haveCount(3))
    expect(results[0].model?.key).to(equal(123))
    expect(results[1].model).to(beNil())
    expect(results[2].model?.key).to(equal(345))
  }

  func testMultipleDifferent() {
    let request1: Request<SingleResult<TestModel1>>
    let request2: Request<SingleResult<TestModel2>>

    do {
      request1 = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?key=1")
        .setMethod(.GET).setXPath("args").build()
      request2 = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?otherKey=2")
        .setMethod(.GET).setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: (Response<SingleResult<TestModel1>>, Response<SingleResult<TestModel2>>)?
    do {
      responses = try Observable.zip(
        Gnomon.models(for: request1),
        Gnomon.models(for: request2)) { ($0, $1) }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let result1 = responses?.0.result, let result2 = responses?.1.result else {
      fail("can't extract responses")
      return
    }

    expect(result1.model.key).to(equal(1))
    expect(result2.model.otherKey).to(equal(2))
  }

  func testMultipleOptionalDifferent() {
    let request1: Request<SingleOptionalResult<TestModel1>>
    let request2: Request<SingleOptionalResult<TestModel2>>

    do {
      request1 = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?key=1")
        .setMethod(.GET).setXPath("args").build()
      request2 = try RequestBuilder()
        .setURLString("\(Params.API.baseURL)/get?failKey=2")
        .setMethod(.GET).setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: (Response<SingleOptionalResult<TestModel1>>, Response<SingleOptionalResult<TestModel2>>)?
    do {
      responses = try Observable.zip(
        Gnomon.models(for: request1), Gnomon.models(for: request2)
      ) { ($0, $1) }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses).toNot(beNil())

    guard let result1 = responses?.0.result, let result2 = responses?.1.result else {
      fail("can't extract responses")
      return
    }

    expect(result1.model?.key).to(equal(1))
    expect(result2.model).to(beNil())
  }

  func testMultipleEmptyArray() {
    let requests = [Request<SingleResult<TestModel1>>]()
    let optionalRequests = [Request<SingleOptionalResult<TestModel1>>]()

    do {
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
