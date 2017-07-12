//
//  XPath.swift
//
//  Created by Vladimir Burdukov on 10/21/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import SwiftyJSON
import AEXML

protocol StringProtocol {

  var length: Int { get }
  func componentsSeparated(by string: String) -> [StringProtocol]

}

extension String: StringProtocol {

  var length: Int { return characters.count }

  func componentsSeparated(by string: String) -> [StringProtocol] {
    return components(separatedBy: string).map { $0 }
  }

}

extension JSON {

  func xpath(_ path: String) -> JSON {
    guard path.length > 0 else { return JSON.null }
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return xpath(components)
  }

  private func xpath(_ components: [String]) -> JSON {
    guard let key = components.first else { return self }
    let value = self[key]
    return value.xpath(Array(components.dropFirst()))
  }

}

extension AEXMLElement {

  func xpath(_ path: String) -> AEXMLElement {
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return xpath(components)
  }

  private func xpath(_ components: [String]) -> AEXMLElement {
    guard let key = components.first else { return self }
    let value = self[key]
    return value.xpath(Array(components.dropFirst()))
  }

}

extension Dictionary where Key: StringProtocol, Value: Any {

  func dictionary(byPath path: Key) -> [Key : Value]? {
    guard path.length > 0 else { return nil }
    let components = path.componentsSeparated(by: "/")
    guard components.count > 0 else { return self }
    return dictionary(byPathComponents: components.flatMap { $0 as? Key })
  }

  func array(byPath path: Key) -> [[Key : Value]]? {
    guard path.length > 0 else { return nil }
    let components = path.componentsSeparated(by: "/")
    guard components.count > 0 else { return nil }
    guard let lastKey = components.last as? Key else { return nil }
    if let dict = dictionary(byPathComponents: components.dropLast().flatMap { $0 as? Key }) {
      return dict[lastKey] as? [[Key : Value]]
    } else {
      return self[lastKey] as? [[Key : Value]]
    }
  }

  private func dictionary(byPathComponents path: [Key]) -> [Key : Value]? {
    guard let key = path.first else { return self }
    guard let value = self[key] as? [Key : Value] else { return nil }
    return value.dictionary(byPathComponents: Array(path.dropFirst()))
  }

}
