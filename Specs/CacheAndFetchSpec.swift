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
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]
    do {
      responses = try Gnomon.cachedThenFetch(request).toBlocking().toArray()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses[0].result.model).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 123
    expect(responses[1].responseType) == ResponseType.regular
  }

  func testNoCachedValueCancel() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/get?key=123").setMethod(.GET)
        .setXPath("args").build()
    } catch {
      fail("\(error)")
      return
    }

    let disposable = Gnomon.cachedThenFetch(request).subscribe()
    disposable.dispose()
  }

  func testCachedValueStored() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]
    do {
      responses = try Gnomon.models(for: request).flatMapLatest { response ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        expect(response.responseType).to(equal(ResponseType.regular))
        return Gnomon.cachedThenFetch(request)
      }.toBlocking().toArray()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses[0].result.model?.key) == 123
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 123
    expect(responses[1].responseType) == ResponseType.httpCache
  }

  func testCachedValueStoredIgnoreCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]
    do {
      responses = try Gnomon.models(for: request).flatMapLatest { response ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        expect(response.responseType).to(equal(ResponseType.regular))
        return Gnomon.cachedThenFetch(request)
      }.toBlocking().toArray()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses[0].result.model).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 123
    expect(responses[1].responseType) == ResponseType.regular
  }

  func testCachedValueStoredIgnoreLocalCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableLocalCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]
    do {
      responses = try Gnomon.models(for: request).flatMapLatest { response ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        expect(response.responseType).to(equal(ResponseType.regular))
        return Gnomon.cachedThenFetch(request)
      }.toBlocking().toArray()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses[0].result.model).to(beNil())
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 123
    expect(responses[1].responseType) == ResponseType.httpCache
  }

  func testCachedValueStoredIgnoreHttpCacheEnabled() {
    let request: Request<SingleOptionalResult<TestModel1>>
    do {
      request = try RequestBuilder<SingleOptionalResult<TestModel1>>()
        .setURLString("\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableHttpCache(true)
        .setXPath("args").build()
    } catch let error {
      fail("\(error)")
      return
    }

    let responses: [Response<SingleOptionalResult<TestModel1>>]
    do {
      responses = try Gnomon.models(for: request).flatMapLatest { response ->
        Observable<Response<SingleOptionalResult<TestModel1>>> in
        expect(response.responseType).to(equal(ResponseType.regular))
        return Gnomon.cachedThenFetch(request)
      }.toBlocking().toArray()
    } catch {
      fail("\(error)")
      return
    }

    expect(responses[0].result.model?.key) == 123
    expect(responses[0].responseType) == ResponseType.localCache
    expect(responses[1].result.model?.key) == 123
    expect(responses[1].responseType) == ResponseType.regular
  }

}
