//
// Created by Vladimir Burdukov on 12/4/17.
// Copyright (c) 2017 NetcoSports. All rights reserved.
//

import XCTest
import Nimble

@testable import Gnomon

class ParamsEncodingSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testEmptyParams() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder()
        .setURLString("http://httpbin.org/post").build()
      expect(try prepareURL(from: request, params: nil).absoluteString).to(equal("http://httpbin.org/post"))
    } catch {
      fail("\(error)")
    }
  }

  func testSimpleDictionary() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder().setURLString("http://httpbin.org/get")
        .build()
      let params = ["key1": "value1", "key2": "value2"]
      let expected = "http://httpbin.org/get?key1=value1&key2=value2"
      expect(try prepareURL(from: request, params: params).absoluteString).to(equal(expected))
    } catch {
      fail("\(error)")
    }
  }

  func testArray() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder().setURLString("http://httpbin.org/get")
        .build()
      let expected = "http://httpbin.org/get?key1=value1&key2=value2&key3%5B%5D=1&key3%5B%5D=2&key3%5B%5D=3"
      let params: [String: Any] = ["key1": "value1", "key2": "value2", "key3": ["1", "2", "3"]]
      expect(try prepareURL(from: request, params: params).absoluteString).to(equal(expected))
    } catch {
      fail("\(error)")
    }
  }

  func testInnerDictionary() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder().setURLString("http://httpbin.org/get")
        .build()
      let params: [String: Any] = ["key1": "value1", "key2": "value2",
                                   "key3": ["inKey1": "inValue1", "inKey2": "inValue2"]]
      let expected = "http://httpbin.org/get?key1=value1&key2=value2&key3%5BinKey1%5D=inValue1&" +
        "key3%5BinKey2%5D=inValue2"
      expect(try prepareURL(from: request, params: params).absoluteString).to(equal(expected))
    } catch {
      fail("\(error)")
    }
  }

  func testInnerDictionaryInArray() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder().setURLString("http://httpbin.org/get")
        .build()
      let params: [String: Any] = ["key1": "value1", "key2": "value2",
                                   "key3": [["inKey1": "inValue1", "inKey2": "inValue2"]]]
      let expected = "http://httpbin.org/get?key1=value1&key2=value2&key3%5B%5D%5BinKey1%5D=inValue1&" +
        "key3%5B%5D%5BinKey2%5D=inValue2"
      expect(try prepareURL(from: request, params: params).absoluteString).to(equal(expected))
    } catch {
      fail("\(error)")
    }
  }

  func testNumbers() {
    do {
      let request: Request<SingleResult<String>> = try RequestBuilder().setURLString("http://httpbin.org/get")
        .build()
      let params: [String: Any] = ["key1": 1, "key2": 2.30]
      let expected = "http://httpbin.org/get?key1=1&key2=2.3"
      expect(try prepareURL(from: request, params: params).absoluteString).to(equal(expected))
    } catch {
      fail("\(error)")
    }
  }

}
