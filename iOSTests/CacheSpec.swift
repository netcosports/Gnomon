//
//  CacheSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 8/8/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import Gnomon

// swiftlint:disable:next type_body_length
class CacheSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testSingleNoCachedValue() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let response: Response<SingleOptionalResult<TestModel1>>?
    do {
      response = try Gnomon.cachedModels(for: request).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(response).notTo(beNil())

    guard let result = response?.result else {
      fail("can't extract response")
      return
    }

    expect(result.model).to(beNil())
    expect(response?.responseType) == ResponseType.localCache
  }

  func testSingleCachedValueStored() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let response: Response<SingleOptionalResult<TestModel1>>?
    do {
      response = try Gnomon.models(for: request).flatMapLatest { _ ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        return Gnomon.cachedModels(for: request)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(response).notTo(beNil())

    guard let result = response?.result else {
      fail("can't extract response")
      return
    }

    expect(result.model?.key) == 123
    expect(response?.responseType) == ResponseType.localCache
  }

  func testSingleCachedValueStoredIgnoreCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let response: Response<SingleOptionalResult<TestModel1>>?
    do {
      response = try Gnomon.models(for: request).flatMapLatest { _ ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        return Gnomon.cachedModels(for: request)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(response).notTo(beNil())

    guard let result = response?.result else {
      fail("can't extract response")
      return
    }

    expect(result.model?.key).to(beNil())
    expect(response?.responseType) == ResponseType.localCache
  }

  func testSingleCachedValueStoredIgnoreLocalCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableLocalCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let response: Response<SingleOptionalResult<TestModel1>>?
    do {
      response = try Gnomon.models(for: request).flatMapLatest { _ ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        return Gnomon.cachedModels(for: request)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(response).notTo(beNil())

    guard let result = response?.result else {
      fail("can't extract response")
      return
    }

    expect(result.model?.key).to(beNil())
    expect(response?.responseType) == ResponseType.localCache
  }

  func testSingleCachedValueStoredIgnoreHttpCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableHttpCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let response: Response<SingleOptionalResult<TestModel1>>?
    do {
      response = try Gnomon.models(for: request).flatMapLatest { _ ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        return Gnomon.cachedModels(for: request)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(response).notTo(beNil())

    guard let result = response?.result else {
      fail("can't extract response")
      return
    }

    expect(result.model?.key) == 123
    expect(response?.responseType) == ResponseType.localCache
  }

  func testMultipleNoCachedValue() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

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

    let responsesOptional: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responsesOptional = try Gnomon.cachedModels(for: requests).toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responsesOptional).notTo(beNil())

    guard let responses = responsesOptional else {
      fail("can't extract response")
      return
    }

    expect(responses).to(haveCount(3))
    expect(responses[0].result.model).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model).to(beNil())
    expect(responses[1].responseType) == ResponseType.localCache
    expect(responses[2].result.model).to(beNil())
    expect(responses[2].responseType) == ResponseType.localCache
  }

  func testMultipleCachedValueStored() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

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

    let responsesOptional: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responsesOptional = try Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responsesOptional).notTo(beNil())

    guard let responses = responsesOptional else {
      fail("can't extract response")
      return
    }

    expect(responses).to(haveCount(3))
    expect(responses[0].result.model?.key) == 123
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 234
    expect(responses[1].responseType) == ResponseType.localCache
    expect(responses[2].result.model).to(beNil())
    expect(responses[2].responseType) == ResponseType.localCache
  }

  func testMultipleCachedValueStoredIgnoreCacheEnabled() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableCache(true)
          .setMethod(.GET).setXPath("args").build()
      }
    } catch let error {
      fail("\(error)")
      return
    }

    let responsesOptional: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responsesOptional = try Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responsesOptional).notTo(beNil())

    guard let responses = responsesOptional else {
      fail("can't extract response")
      return
    }

    expect(responses).to(haveCount(3))
    expect(responses[0].result.model?.key).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key).to(beNil())
    expect(responses[1].responseType) == ResponseType.localCache
    expect(responses[2].result.model).to(beNil())
    expect(responses[2].responseType) == ResponseType.localCache
  }

  func testMultipleCachedValueStoredIgnoreLocalCacheEnabled() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableLocalCache(true)
          .setMethod(.GET).setXPath("args").build()
      }
    } catch let error {
      fail("\(error)")
      return
    }

    let responsesOptional: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responsesOptional = try Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responsesOptional).notTo(beNil())

    guard let responses = responsesOptional else {
      fail("can't extract response")
      return
    }

    expect(responses).to(haveCount(3))
    expect(responses[0].result.model?.key).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key).to(beNil())
    expect(responses[1].responseType) == ResponseType.localCache
    expect(responses[2].result.model).to(beNil())
    expect(responses[2].responseType) == ResponseType.localCache
  }

  func testMultipleCachedValueStoredIgnoreHttpCacheEnabled() {
    let requests: [Request<SingleOptionalResult<TestModel1>>]

    do {
      requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableHttpCache(true)
          .setMethod(.GET).setXPath("args").build()
      }
    } catch let error {
      fail("\(error)")
      return
    }

    let responsesOptional: [Response<SingleOptionalResult<TestModel1>>]?
    do {
      responsesOptional = try Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().first()
    } catch {
      fail("\(error)")
      return
    }

    expect(responsesOptional).notTo(beNil())

    guard let responses = responsesOptional else {
      fail("can't extract response")
      return
    }

    expect(responses).to(haveCount(3))
    expect(responses[0].result.model?.key) == 123
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 234
    expect(responses[1].responseType) == ResponseType.localCache
    expect(responses[2].result.model).to(beNil())
    expect(responses[2].responseType) == ResponseType.localCache
  }

}
