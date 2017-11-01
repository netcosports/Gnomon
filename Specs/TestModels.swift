//
//  Common.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 7/6/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import SwiftyJSON
import AEXML
import Gnomon

struct TestModel1: JSONModel {

  let key: Int

  init(_ json: JSON) throws {
    guard let string = json["key"].string, let value = Int(string) else {
      throw Gnomon.Error.unableToParseModel("<key> value is invalid = <\(json["key"])>")
    }

    key = value
  }

}

struct TestModel2: JSONModel {

  let otherKey: Int

  init(_ json: JSON) throws {
    guard let string = json["otherKey"].string, let value = Int(string) else {
      throw Gnomon.Error.unableToParseModel("<key> value is invalid = <\(json["otherKey"])>")
    }

    otherKey = value
  }

}

struct TestModel3: JSONModel {

  let key1: Int
  let key2: Int
  let keys: [Int]

  init(_ json: JSON) throws {
    guard let string1 = json["args"]["key1"].string, let value1 = Int(string1) else {
      throw Gnomon.Error.unableToParseModel("<key1> value is invalid = <\(json["args"]["key1"])>")
    }

    guard let string2 = json["args"]["key2"].string, let value2 = Int(string2) else {
      throw Gnomon.Error.unableToParseModel("<key2> value is invalid = <\(json["args"]["key2"])>")
    }

    guard let ints = json["args"]["key3[]"].array else {
      throw Gnomon.Error.unableToParseModel("<key3> value is invalid = <\(json["args"]["key3[]"])>")
    }

    key1 = value1
    key2 = value2
    keys = ints.flatMap({ $0.string }).flatMap { Int($0) }
  }

}

struct TestModel4: JSONModel {

  let key1: Int
  let key2: Int

  init(_ json: JSON) throws {
    guard let string1 = json["args"]["key1"].string, let value1 = Int(string1) else {
      throw Gnomon.Error.unableToParseModel("<key1> value is invalid = <\(json["args"]["key1"])>")
    }

    guard let string2 = json["form"]["key2"].string, let value2 = Int(string2) else {
      throw Gnomon.Error.unableToParseModel("<key2> value is invalid = <\(json["form"]["key2"])>")
    }

    key1 = value1
    key2 = value2
  }

}

struct TestModel5: JSONModel {

  let key: Int

  init(_ json: JSON) throws {
    guard let string = json["args"]["key"].string, let value = Int(string) else {
      throw Gnomon.Error.unableToParseModel("<key> value is invalid = <\(json["args"]["key"])>")
    }

    key = value
  }

}

struct TestModel6: JSONModel {

  let key: Int

  init(_ json: JSON) throws {
    guard let string = json["json"]["key"].string, let value = Int(string) else {
      throw Gnomon.Error.unableToParseModel("<key> value is invalid = <\(json["json"]["key"])>")
    }

    key = value
  }

}

struct TestModel7: JSONModel {

  let key1: Int
  let key2: Int

  init(_ json: JSON) throws {
    guard let string1 = json["args"]["key1"].string, let value1 = Int(string1) else {
      throw Gnomon.Error.unableToParseModel("<key1> value is invalid = <\(json["args"]["key1"])>")
    }

    guard let string2 = json["json"]["key2"].string, let value2 = Int(string2) else {
      throw Gnomon.Error.unableToParseModel("<key2> value is invalid = <\(json["json"]["key2"])>")
    }

    key1 = value1
    key2 = value2
  }

}

struct TestModel8: JSONModel {

  let headers: [String: String]

  init(_ json: JSON) throws {
    headers = json["headers"].dictionaryValue.reduce([String: String]()) { result, tuple in
      let (key, json) = tuple
      var result = result
      result[key] = json.stringValue
      return result
    }
  }

}

struct TestXMLModel: XMLModel {

  let title: String

  init(_ xml: AEXMLElement) throws {
    guard let title = xml.attributes["title"] else {
      let value = String(describing: xml.attributes["title"])
      throw Gnomon.Error.unableToParseModel("<_title> value is invalid = <\(value)>")
    }

    self.title = title
  }

}

struct TestXMLSlideModel: XMLModel {

  let title: String

  init(_ xml: AEXMLElement) throws {
    guard let title = xml["title"].value else {
      let value = String(describing: xml.attributes["title"])
      throw Gnomon.Error.unableToParseModel("<_title> value is invalid = <\(value)>")
    }

    self.title = title
  }

}

struct AuthorizationHeaderModel: JSONModel {

  let authorization: String

  init(_ json: JSON) throws {
    guard let string = json["Authorization"].string else {
      throw Gnomon.Error.unableToParseModel(
        "<Authorization> value is invalid = <\(json["Authorization"])>"
      )
    }

    authorization = string

  }

}

extension Data {

  func sha1() -> Data {
    return Data(bytes: bytes.sha1())
  }

  func md5() -> Data {
    return Data(bytes: bytes.md5())
  }

  var bytes: [UInt8] {
    return Array(self)
  }

  func toHexString() -> String {
    return self.bytes.toHexString()
  }

}

extension Array where Iterator.Element == UInt8 {

  func sha1() -> [UInt8] {
    var digest = [UInt8].init(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    CC_SHA1(self, UInt32(count), &digest)
    return digest
  }

  func md5() -> [UInt8] {
    var digest = [UInt8].init(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5(self, UInt32(count), &digest)
    return digest
  }

  func toHexString() -> String {
    return self.lazy.reduce("") {
      var s = String($1, radix: 16)
      if s.count == 1 {
        s = "0" + s
      }
      return $0 + s
    }
  }

}
