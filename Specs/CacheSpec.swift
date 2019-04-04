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

  func testSingleNoCachedValue() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.cacheSessionDelegate = TestSessionDelegate.noCacheResponse()

      let result = Gnomon.cachedModels(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(0))
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testSingleCachedValueStored() {
    do {
      let request = try Request<TestModel1>(URLString: "https://example.com/")
      request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": 123], cached: true)

      let result = Gnomon.cachedModels(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        expect(responses[0].result.key) == 123
        expect(responses[0].type) == .localCache
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleNoCachedValue() {
    do {
      let requests = try (0 ... 2).map { _ -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        request.cacheSessionDelegate = TestSessionDelegate.noCacheResponse()
        return request
      }

      let result = Gnomon.cachedModels(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        for result in results {
          switch result {
          case .success: fail("request should fail")
          case let .failure(error):
            let error = error as NSError
            expect(error.domain) == NSURLErrorDomain
            expect(error.code) == NSURLErrorResourceUnavailable
          }
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMultipleCachedValueStored() {
    do {
      let requests = try (0 ... 2).map { 123 + 111 * $0 }.map { value -> Request<TestModel1> in
        let request = try Request<TestModel1>(URLString: "https://example.com")
        if value != 234 {
          request.cacheSessionDelegate = try TestSessionDelegate.jsonResponse(result: ["key": value], cached: true)
        } else {
          request.cacheSessionDelegate = TestSessionDelegate.noCacheResponse()
        }
        return request
      }

      let result = Gnomon.cachedModels(for: requests).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(elements):
        expect(elements).to(haveCount(1))

        let results = elements[0]
        expect(results).to(haveCount(3))

        switch results[0] {
        case let .success(value):
          expect(value.result.key) == 123
          expect(value.type) == .localCache
        case let .failure(error): fail("\(error)")
        }

        switch results[1] {
        case .success: fail("request should fail")
        case let .failure(error):
          let error = error as NSError
          expect(error.domain) == NSURLErrorDomain
          expect(error.code) == NSURLErrorResourceUnavailable
        }

        switch results[2] {
        case let .success(value):
          expect(value.result.key) == 345
          expect(value.type) == .localCache
        case let .failure(error): fail("\(error)")
        }
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

}
