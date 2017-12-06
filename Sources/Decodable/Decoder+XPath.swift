//
//  Created by Vladimir Burdukov on 05/12/2017.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Foundation

public struct Path: CodingKey {
  public enum Component {
    case key(String)
    case arrayIndex(String, Int)

    init(_ string: String) {
      do {
        guard string.hasSuffix("]") else { throw "" }

        guard let openRange = string.range(of: "[") else { throw "" }
        guard let closeRange = string.range(of: "]", options: [.backwards]) else { throw "" }

        let substring = string[openRange.upperBound..<closeRange.lowerBound]
        guard let int = Int(substring) else { throw "" }

        self = .arrayIndex(String(string[..<openRange.lowerBound]), int)
      } catch {
        self = .key(string)
      }
    }
  }

  public init?(stringValue: String) {
    self.init(stringComponents: [stringValue])
  }

  public init(stringComponents: [String]) {
    self.components = stringComponents.map { Component($0) }
  }

  public var stringValue: String {
    switch components[0] {
    case let .key(key): return key
    case let .arrayIndex(key, _): return key
    }
  }

  public var intValue: Int? {
    switch components[0] {
    case .key: return nil
    case .arrayIndex(_, let idx): return idx
    }
  }

  public init?(intValue: Int) { return nil }

  public let components: [Component]

  public init(components: [Component]) {
    self.components = components
  }

  public var next: Path {
    var components = self.components
    _ = components.removeFirst()
    return Path(components: components)
  }
}

extension Path {

  private func parseArraySubscript(_ string: String) -> (String, Int?) {
    guard string.hasSuffix("]") else { return (string, nil) }

    guard let openRange = string.range(of: "[") else { return (string, nil) }
    guard let closeRange = string.range(of: "]", options: [.backwards]) else { return (string, nil) }

    let substring = string[openRange.upperBound..<closeRange.lowerBound]
    guard let int = Int(substring) else { return (string, nil) }

    return (String(string[..<openRange.lowerBound]), int)
  }

}

public extension Decoder {

  func decoder(by stringPath: String?) throws -> Decoder {
    guard let stringPath = stringPath else { return self }
    return try decoder(by: Path(stringComponents: stringPath.components(separatedBy: "/")))
  }

  func decoder(by path: Path) throws -> Decoder {
    var decoder: Decoder = self
    var path = path
    while path.components.count > 0 {
      if let index = path.intValue {
        var container = try decoder.container(keyedBy: Path.self).nestedUnkeyedContainer(forKey: path)
        while container.currentIndex < index {
          _ = try container.superDecoder()
        }
        decoder = try container.superDecoder()
      } else {
        decoder = try decoder.container(keyedBy: Path.self).superDecoder(forKey: path)
      }

      path = path.next
    }
    return decoder
  }

}
