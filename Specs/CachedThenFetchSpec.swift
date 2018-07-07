//
//  CachedThenFetchSpec.swift
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

  func testNoCachedValue() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.cacheSessionDelegate = TestSessionDelegate.noCacheResponse()
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)

      let result = Gnomon.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .regular
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testCachedValueStored() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)

      let result = Gnomon.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(2))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache

        expect(responses[1].result.key) == 123
        expect(responses[1].type) == .httpCache
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testOutdatedCachedValueStored() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: false)

      let result = Gnomon.cachedThenFetch(request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(2))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache

        expect(responses[1].result.key) == 123
        expect(responses[1].type) == .regular
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  // TODO: should be tested in Request<Model> → URLRequest conversion spec

//  func testCachedValueStoredIgnoreCacheEnabled() {
//    do {
//      let request = try Request<TestModel1?>(URLString: "\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableCache(true)
//        .setXPath("args")
//
//      let responses = try Gnomon.models(for: request)
//        .flatMapLatest { response -> Observable<Response<TestModel1?>> in
//          expect(response.type).to(equal(.regular))
//          return Gnomon.cachedThenFetch(request)
//        }.toBlocking(timeout: BlockingTimeout).toArray()
//
//      expect(responses).to(haveCount(1))
//
//      expect(responses[0].result?.key) == 123
//      expect(responses[0].type) == .regular
//    } catch {
//      fail("\(error)")
//      return
//    }
//  }
//
//  func testCachedValueStoredIgnoreLocalCacheEnabled() {
//    do {
//      let request = try Request<TestModel1?>(URLString: "\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableLocalCache(true)
//        .setXPath("args")
//
//      let responses = try Gnomon.models(for: request)
//        .flatMapLatest { response -> Observable<Response<TestModel1?>> in
//          expect(response.type).to(equal(.regular))
//          return Gnomon.cachedThenFetch(request)
//        }.toBlocking(timeout: BlockingTimeout).toArray()
//
//      expect(responses).to(haveCount(1))
//
//      expect(responses[0].result?.key) == 123
//      expect(responses[0].type) == .httpCache
//    } catch {
//      fail("\(error)")
//      return
//    }
//  }
//
//  func testCachedValueStoredIgnoreHttpCacheEnabled() {
//    do {
//      let request = try Request<TestModel1?>(URLString: "\(Params.API.baseURL)/cache/120?key=123").setMethod(.GET).setDisableHttpCache(true)
//        .setXPath("args")
//
//      let responses = try Gnomon.models(for: request)
//        .flatMapLatest { response -> Observable<Response<TestModel1?>> in
//          expect(response.type).to(equal(.regular))
//          return Gnomon.cachedThenFetch(request)
//        }.toBlocking(timeout: BlockingTimeout).toArray()
//
//      expect(responses).to(haveCount(2))
//
//      expect(responses[0].result?.key) == 123
//      expect(responses[0].type) == .localCache
//      expect(responses[1].result?.key) == 123
//      expect(responses[1].type) == .regular
//    } catch {
//      fail("\(error)")
//      return
//    }
//  }

}
