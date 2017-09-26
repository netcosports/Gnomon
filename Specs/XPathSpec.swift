//
//  XPathSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 10/21/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import XCTest
import Nimble

@testable import Gnomon

class XPathSpec: XCTestCase {

  static let testDictionary: [String: Any] = [
    "root": [
      "inner": ["@attributes": ["uID": "p180593"], "@value": "Ronald Matarrita"],
      "multiple": [
        ["@attributes": ["uID": "p180593"], "@value": "Ronald Matarrita"],
        ["@attributes": ["uID": "p50122"], "@value": "Sean Franklin"],
        ["@attributes": ["uID": "p60152"], "@value": "Chris Pontius"]
      ]
    ],
    "one_level": ["key": "value"]
  ]

  func testOneLevelDictionaryXPath() {
    let result = XPathSpec.testDictionary.dictionary(byPath: "one_level")
    expect(result?["key"] as? String).to(equal("value"))
  }

  func testMoreLevelsDictionaryXPath() {
    let result = XPathSpec.testDictionary.dictionary(byPath: "root/inner")
    expect(result?["@value"] as? String).to(equal("Ronald Matarrita"))
    expect(result?["@attributes"] as? [String: String]).to(equal(["uID": "p180593"]))
  }

  func testArrayXPath() {
    let result = XPathSpec.testDictionary.array(byPath: "root/multiple")
    guard let array = result else {
      fail()
      return
    }

    expect(array).to(haveCount(3))
    expect(array[0]["@value"] as? String).to(equal("Ronald Matarrita"))
    expect(array[1]["@value"] as? String).to(equal("Sean Franklin"))
    expect(array[2]["@value"] as? String).to(equal("Chris Pontius"))
  }

  func testInvalidXPaths() {
    let firstLevel = XPathSpec.testDictionary.dictionary(byPath: "invalid")
    let secondLevel = XPathSpec.testDictionary.dictionary(byPath: "root/invalid")

    expect(firstLevel).to(beNil())
    expect(secondLevel).to(beNil())
  }

}
