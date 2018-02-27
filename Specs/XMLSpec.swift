//
//  XMLSpec.swift
//  Tests
//
//  Created by Vladimir Burdukov on 27/8/17.
//
//

import XCTest
import Gnomon
import Nimble
import RxBlocking

class XMLSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
    Gnomon.removeAllInterceptors()
  }

  func testPlainXMLRequest() {
    do {
      let request = try RequestBuilder<TestXMLModel>()
        .setURLString("\(Params.API.baseURL)/xml").setMethod(.GET).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result.title).to(equal("Sample Slide Show"))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainMultipleXMLRequest() {
    do {
      let request = try RequestBuilder<[TestXMLSlideModel]>()
        .setURLString("\(Params.API.baseURL)/xml").setXPath("slideshow/slide")
        .setMethod(.GET).build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      guard let result = response?.result else { throw "can't extract response" }

      expect(result[0].title).to(equal("Wake up to WonderWidgets!"))
      expect(result[1].title).to(equal("Overview"))
    } catch {
      fail("\(error)")
      return
    }
  }

}
