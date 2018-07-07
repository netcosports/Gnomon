//
//  XMLSpec.swift
//  Tests
//
//  Created by Vladimir Burdukov on 27/8/17.
//
//

import XCTest
import Nimble
import RxBlocking

@testable import Gnomon

class XMLSpec: XCTestCase {

  func testPlainXMLRequest() {
    do {
      let request = try Request<TestXMLModel>(URLString: "https://example.com").setXPath("data")

      let xml = """
<?xml version='1.0' encoding='utf8'?>
<data key="123">
</data>
"""
      request.httpSessionDelegate = try TestSessionDelegate.stringResponse(result: xml, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))
        expect(responses[0].result.key) == 123
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlainMultipleXMLRequest() {
    do {
      let request = try Request<[TestXMLModel]>(URLString: "https://example.com").setXPath("data/item")

      let xml = """
<?xml version='1.0' encoding='utf8'?>
<data>
  <item key="123" />
  <item key="234" />
</data>
"""
      request.httpSessionDelegate = try TestSessionDelegate.stringResponse(result: xml, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        expect(responses[0].result).to(haveCount(2))
        expect(responses[0].result[0].key) == 123
        expect(responses[0].result[1].key) == 234
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

}
