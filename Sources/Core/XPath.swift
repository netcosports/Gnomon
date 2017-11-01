//
//  Created by Vladimir Burdukov on 10/21/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value: Any {

  func dictionary(byPath path: Key) -> [Key: Value]? {
    guard path.count > 0 else { return nil }
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return self }
    return dictionary(byPathComponents: ArraySlice(components))
  }

  func array(byPath path: Key) -> [[Key: Value]]? {
    guard path.count > 0 else { return nil }
    let components = path.components(separatedBy: "/")
    guard components.count > 0 else { return nil }
    guard let lastKey = components.last else { return nil }
    if let dict = dictionary(byPathComponents: components.dropLast()) {
      return dict[lastKey] as? [[Key: Value]]
    } else {
      return self[lastKey] as? [[Key: Value]]
    }
  }

  private func dictionary(byPathComponents path: ArraySlice<Key>) -> [Key: Value]? {
    guard let key = path.first else { return self }
    guard let value = self[key] as? [Key: Value] else { return nil }
    return value.dictionary(byPathComponents: path.dropFirst())
  }

}
