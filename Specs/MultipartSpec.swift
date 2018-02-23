//
// Created by Vladimir Burdukov on 18/5/17.
// Copyright (c) 2017 NetcoSports. All rights reserved.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking
import SwiftyJSON

@testable import Gnomon

struct MultipartModel: JSONModel {

  let files: [String: String]
  let form: [String: String]

  init(_ json: JSON) throws {
    files = json["files"].dictionaryValue.reduce([:]) { result, tuple in
      var result = result
      if let string = tuple.value.string {
        result[tuple.key] = string
      }
      return result
    }

    form = json["form"].dictionaryValue.reduce([:]) { result, tuple in
      var result = result
      if let string = tuple.value.string {
        result[tuple.key] = string
      }
      return result
    }
  }

}

class MultipartSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
  }

  func testSimpleParams() {
    do {
      let request = try RequestBuilder<SingleResult<MultipartModel>>()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.multipart(["text": "Hello World", "number": "42"], [:])).build()
      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      expect(result.model.files).to(beEmpty())
      expect(result.model.form).to(equal(["text": "Hello World", "number": "42"]))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testFiles() {
    do {
      guard let url = Bundle(for: type(of: self)).url(forResource: "test_file", withExtension: "zip") else {
        return fail("can't find test file")
      }

      let data = try Data(contentsOf: url)
      let file = MultipartFile(data: data, contentType: "application/zip", filename: "test_file.zip")

      let request = try RequestBuilder<SingleResult<MultipartModel>>()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.multipart([:], ["file": file])).build()
      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let files = [
        "file": "data:application/zip;base64,\(data.base64EncodedString())"
      ]
      expect(result.model.files).to(equal(files))
      expect(result.model.form).to(beEmpty())
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMixed() {
    do {
      guard let url = Bundle(for: type(of: self)).url(forResource: "test_file", withExtension: "zip") else {
        return fail("can't find test file")
      }

      let data = try Data(contentsOf: url)
      let file = MultipartFile(data: data, contentType: "application/zip", filename: "test_file.zip")

      let request = try RequestBuilder<SingleResult<MultipartModel>>()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST)
        .setParams(.multipart(["text": "Hello World", "number": "42"], ["file": file])).build()
      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let files = [
        "file": "data:application/zip;base64,\(data.base64EncodedString())"
      ]
      expect(result.model.files).to(equal(files))
      expect(result.model.form).to(equal(["text": "Hello World", "number": "42"]))
    } catch {
      fail("\(error)")
      return
    }
  }

}
