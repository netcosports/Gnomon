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
    do {
      let request = try RequestBuilder<TestModel1?>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()

      let sequence = Gnomon.cachedModels(for: request).toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(0))
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleCachedValueStored() {
    do {
      let request = try RequestBuilder<TestModel1?>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()

      let sequence = Gnomon.models(for: request)
        .flatMapLatest { _ -> Observable<Response<TestModel1?>> in
          return Gnomon.cachedModels(for: request)
        }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        expect(elements[0].result?.key) == 123
        expect(elements[0].type) == .localCache
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleCachedValueStoredIgnoreCacheEnabled() {
    do {
      let request = try RequestBuilder<TestModel1?>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableCache(true)
        .setXPath("args").build()

      let sequence = Gnomon.models(for: request)
        .flatMapLatest { _ -> Observable<Response<TestModel1?>> in
          return Gnomon.cachedModels(for: request)
        }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(0))
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleCachedValueStoredIgnoreLocalCacheEnabled() {
    do {
      let request = try RequestBuilder<TestModel1?>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableLocalCache(true)
        .setXPath("args").build()

      let sequence = Gnomon.models(for: request)
        .flatMapLatest { _ -> Observable<Response<TestModel1?>> in
          return Gnomon.cachedModels(for: request)
        }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(0))
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleCachedValueStoredIgnoreHttpCacheEnabled() {
    do {
      let request = try RequestBuilder<TestModel1?>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET).setDisableHttpCache(true)
        .setXPath("args").build()

      let sequence = Gnomon.models(for: request)
        .flatMapLatest { _ -> Observable<Response<TestModel1?>> in
          return Gnomon.cachedModels(for: request)
        }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        expect(elements[0].result?.key) == 123
        expect(elements[0].type) == .localCache
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleNoCachedValue() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }

      let sequence = Gnomon.cachedModels(for: requests).toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let responses = elements[0]
        expect(responses).to(haveCount(3))
        for response in responses {
          expect(response).notTo(beNil())
          expect(response.error).notTo(beNil())
        }
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleCachedValueStored() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1?>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)")
          .setMethod(.GET).setXPath("args").build()
      }
      let sequence = Gnomon.models(for: Array(requests.dropLast())).debug().flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.debug().toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let responses = elements[0]

        expect(responses).to(haveCount(3))
        expect(responses[0].value?.result?.key) == 123
        expect(responses[0].value?.type) == .localCache
        expect(responses[1].value?.result?.key) == 234
        expect(responses[1].value?.type) == .localCache
        expect(responses[2].value).to(beNil())
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleCachedValueStoredIgnoreCacheEnabled() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1?>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableCache(true)
          .setMethod(.GET).setXPath("args").build()
      }

      let sequence = Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let responses = elements[0]
        expect(responses).to(haveCount(3))
        for response in responses {
          expect(response).notTo(beNil())
          expect(response.error).notTo(beNil())
        }
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleCachedValueStoredIgnoreLocalCacheEnabled() {

    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1?>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableLocalCache(true)
          .setMethod(.GET).setXPath("args").build()
      }

      let sequence = Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let responses = elements[0]
        expect(responses).to(haveCount(3))
        for response in responses {
          expect(response).notTo(beNil())
          expect(response.error).notTo(beNil())
        }
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleCachedValueStoredIgnoreHttpCacheEnabled() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map {
        return try RequestBuilder<TestModel1?>()
          .setURLString("\(Params.API.baseURL)/get?key=\($0)").setDisableHttpCache(true)
          .setMethod(.GET).setXPath("args").build()
      }

      let sequence = Gnomon.models(for: Array(requests.dropLast())).flatMapLatest { _ in
        return Gnomon.cachedModels(for: requests)
      }.toBlocking().materialize()

      switch sequence {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let responses = elements[0]
        expect(responses).to(haveCount(3))

        expect(responses[0].value).notTo(beNil())
        expect(responses[0].value?.result?.key) == 123
        expect(responses[0].value?.type) == .localCache

        expect(responses[1].value).notTo(beNil())
        expect(responses[1].value?.result?.key) == 234
        expect(responses[1].value?.type) == .localCache

        expect(responses[2].value).to(beNil())
      case let .failed(_, error):
        throw error
      }
    } catch {
      fail("\(error)")
      return
    }
  }

}
