//
// Created by Vladimir Burdukov on 12/4/17.
// Copyright (c) 2017 NetcoSports. All rights reserved.
//

import XCTest
import Nimble

@testable import Gnomon

class URLParamsEncodingSpec: XCTestCase {

  func testEmptyParams() {
    do {
      let request = try Request<String>(URLString: "https://example.com/post")
      expect(try prepareURL(with: request.url, params: nil).absoluteString) == "https://example.com/post"
    } catch {
      fail("\(error)")
    }
  }

  func testSimpleDictionary() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get")

      let params = ["key1": "value1", "key2": "value2"]
      let expected = "https://example.com/get?key1=value1&key2=value2"
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

  func testArray() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get")

      let expected = "https://example.com/get?key1=value1&key2=value2&key3%5B%5D=1&key3%5B%5D=2&key3%5B%5D=3"
      let params: [String: Any] = ["key1": "value1", "key2": "value2", "key3": ["1", "2", "3"]]
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

  func testInnerDictionary() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get")

      let params: [String: Any] = ["key1": "value1", "key2": "value2",
                                   "key3": ["inKey1": "inValue1", "inKey2": "inValue2"]]
      let expected = "https://example.com/get?key1=value1&key2=value2&key3%5BinKey1%5D=inValue1&" +
        "key3%5BinKey2%5D=inValue2"
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

  func testInnerDictionaryInArray() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get")

      let params: [String: Any] = ["key1": "value1", "key2": "value2",
                                   "key3": [["inKey1": "inValue1", "inKey2": "inValue2"]]]
      let expected = "https://example.com/get?key1=value1&key2=value2&key3%5B%5D%5BinKey1%5D=inValue1&" +
        "key3%5B%5D%5BinKey2%5D=inValue2"
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

  func testNumbers() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get")

      let params: [String: Any] = ["key1": 1, "key2": 2.30]
      let expected = "https://example.com/get?key1=1&key2=2.3"
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

  func testRequestWithParamsInURL() {
    do {
      let request = try Request<String>(URLString: "https://example.com/get?key3=value3").setMethod(.GET)

      let params = ["key1": "value1", "key2": "value2"]
      let expected = "https://example.com/get?key1=value1&key2=value2&key3=value3"
      expect(try prepareURL(with: request.url, params: params).absoluteString) == expected
    } catch {
      fail("\(error)")
    }
  }

}
