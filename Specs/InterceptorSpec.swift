//
//  InterceptorSpec.swift
//  Tests
//
//  Created by Vladimir Burdukov on 27/8/17.
//
//

import XCTest
import Gnomon
import Nimble
import RxBlocking

class InterceptorSpec: XCTestCase {

  // TODO: should be tested in Request<Model> → URLRequest conversion spec

//  func testGlobalInterceptor() {
//    Gnomon.addRequestInterceptor { request in
//      var request = request
//      if let data = request.httpBody {
//        request.addValue(data.sha1().toHexString(), forHTTPHeaderField: "X-Sha1-Signature")
//      }
//      return request
//    }
//
//    do {
//      let request = try Request<TestModel8>(URLString: "\(Params.API.baseURL)/post")
//        .setParams(["test": "test"]).setMethod(.POST)
//      guard let response = try Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).first() else {
//        return fail("can't extract response")
//      }
//      expect(response.result.headers["X-Sha1-Signature"]) == "b3cefbcce711f8574b0e66c41fc1dcf06eb5b6db"
//    } catch {
//      fail("\(error)")
//    }
//
//    do {
//      let request = try Request<TestModel8>(URLString: "\(Params.API.baseURL)/get")
//        .setMethod(.GET)
//      guard let response = try Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).first() else {
//        return fail("can't extract response")
//      }
//      expect(response.result.headers["X-Sha1-Signature"]).to(beNil())
//    } catch {
//      fail("\(error)")
//    }
//  }
//
//  func testCustomExclusiveInterceptor() {
//    Gnomon.addRequestInterceptor { request in
//      var request = request
//      if let data = request.httpBody {
//        request.addValue(data.sha1().toHexString(), forHTTPHeaderField: "X-Sha1-Signature")
//      }
//      return request
//    }
//
//    do {
//      let interceptor: Interceptor = { request in
//        var request = request
//        if let data = request.httpBody {
//          request.addValue(data.md5().toHexString(), forHTTPHeaderField: "X-Md5-Signature")
//        }
//        return request
//      }
//      let request = try Request<TestModel8>(URLString: "\(Params.API.baseURL)/post")
//        .setParams(["test": "test"]).setMethod(.POST).setInterceptor(interceptor, exclusive: true)
//      guard let response = try Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).first() else {
//        return fail("can't extract response")
//      }
//      expect(response.result.headers["X-Md5-Signature"]) == "d14091e1796351152f0ba2a5940606d7"
//      expect(response.result.headers["X-Sha1-Signature"]).to(beNil())
//    } catch {
//      fail("\(error)")
//    }
//  }
//
//  func testCustomNonexclusiveInterceptor() {
//    Gnomon.addRequestInterceptor { request in
//      var request = request
//      if let data = request.httpBody {
//        request.addValue(data.sha1().toHexString(), forHTTPHeaderField: "X-Sha1-Signature")
//      }
//      return request
//    }
//
//    do {
//      let interceptor: Interceptor = { request in
//        var request = request
//        if let data = request.httpBody {
//          request.addValue(data.md5().toHexString(), forHTTPHeaderField: "X-Md5-Signature")
//        }
//        return request
//      }
//      let request = try Request<TestModel8>(URLString: "\(Params.API.baseURL)/post")
//        .setParams(["test": "test"]).setMethod(.POST).setInterceptor(interceptor, exclusive: false)
//      guard let response = try Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).first() else {
//        return fail("can't extract response")
//      }
//      expect(response.result.headers["X-Md5-Signature"]) == "d14091e1796351152f0ba2a5940606d7"
//      expect(response.result.headers["X-Sha1-Signature"]) == "b3cefbcce711f8574b0e66c41fc1dcf06eb5b6db"
//    } catch {
//      fail("\(error)")
//    }
//  }
//
//  func testCustomNonexclusiveInterceptorOrder() {
//    Gnomon.addRequestInterceptor { request in
//      var request = request
//      if let data = request.httpBody {
//        request.addValue(data.sha1().toHexString(), forHTTPHeaderField: "X-Signature")
//      }
//      return request
//    }
//
//    do {
//      let interceptor: Interceptor = { request in
//        var request = request
//        if let data = request.httpBody {
//          request.addValue(data.md5().toHexString(), forHTTPHeaderField: "X-Signature")
//        }
//        return request
//      }
//      let request = try Request<TestModel8>(URLString: "\(Params.API.baseURL)/post")
//        .setParams(["test": "test"]).setMethod(.POST).setInterceptor(interceptor, exclusive: false)
//      guard let response = try Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).first() else {
//        return fail("can't extract response")
//      }
//      expect(response.result.headers["X-Signature"]) == "d14091e1796351152f0ba2a5940606d7," +
//      "b3cefbcce711f8574b0e66c41fc1dcf06eb5b6db"
//    } catch {
//      fail("\(error)")
//    }
//  }

}
