//
//  CacheAndFetchSpec.swift
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

class CacheAndFetchSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testNoCachedValue() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()
      let responses = try Gnomon.cachedThenFetch(request).toBlocking().toArray()

      expect(responses).to(haveCount(2))

      expect(responses[0].result.model).to(beNil())
      expect(responses[0].responseType) == ResponseType.localCache
      expect(responses[1].result.model?.key) == 123
      expect(responses[1].responseType) == ResponseType.regular
    } catch {
      fail("\(error)")
      return
    }
  }

  func testNoCachedValueCancel() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()

      let disposable = Gnomon.cachedThenFetch(request).subscribe()
      disposable.dispose()
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCachedValueStored() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET)
        .setXPath("args").build()

      let responses = try Gnomon.models(for: request)
        .flatMapLatest { response -> Observable<Response<SingleOptionalResult<TestModel1>>> in
          expect(response.responseType).to(equal(ResponseType.regular))
          return Gnomon.cachedThenFetch(request)
        }.toBlocking().toArray()

      expect(responses).to(haveCount(2))

      expect(responses[0].result.model?.key) == 123
      expect(responses[0].responseType) == ResponseType.localCache
      expect(responses[1].result.model?.key) == 123
      expect(responses[1].responseType) == ResponseType.httpCache
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCachedValueStoredIgnoreCacheEnabled() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableCache(true)
        .setXPath("args").build()

      let responses = try Gnomon.models(for: request)
        .flatMapLatest { response -> Observable<Response<SingleOptionalResult<TestModel1>>> in
          expect(response.responseType).to(equal(ResponseType.regular))
          return Gnomon.cachedThenFetch(request)
        }.toBlocking().toArray()

      expect(responses).to(haveCount(2))

      expect(responses[0].result.model).to(beNil())
      expect(responses[0].responseType) == ResponseType.localCache
      expect(responses[1].result.model?.key) == 123
      expect(responses[1].responseType) == ResponseType.regular
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCachedValueStoredIgnoreLocalCacheEnabled() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableLocalCache(true)
        .setXPath("args").build()

      let responses = try Gnomon.models(for: request)
        .flatMapLatest { response -> Observable<Response<SingleOptionalResult<TestModel1>>> in
          expect(response.responseType).to(equal(ResponseType.regular))
          return Gnomon.cachedThenFetch(request)
        }.toBlocking().toArray()

      expect(responses).to(haveCount(2))

      expect(responses[0].result.model).to(beNil())
      expect(responses[0].responseType) == ResponseType.localCache
      expect(responses[1].result.model?.key) == 123
      expect(responses[1].responseType) == ResponseType.httpCache
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCachedValueStoredIgnoreHttpCacheEnabled() {
    do {
      let request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableHttpCache(true)
        .setXPath("args").build()

      let responses = try Gnomon.models(for: request)
        .flatMapLatest { response -> Observable<Response<SingleOptionalResult<TestModel1>>> in
          expect(response.responseType).to(equal(ResponseType.regular))
          return Gnomon.cachedThenFetch(request)
        }.toBlocking().toArray()

      expect(responses).to(haveCount(2))

      expect(responses[0].result.model?.key) == 123
      expect(responses[0].responseType) == ResponseType.localCache
      expect(responses[1].result.model?.key) == 123
      expect(responses[1].responseType) == ResponseType.regular
    } catch {
      fail("\(error)")
      return
    }
  }

}
