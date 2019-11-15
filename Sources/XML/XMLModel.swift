//
//  Created by Vladimir Burdukov on 08/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Foundation
import AEXML
#if SWIFT_PACKAGE
  import Core
#endif

public protocol XMLModel: BaseModel where DataContainer == XMLContainer {

  init(_ xml: AEXMLElement) throws

}

extension XMLModel {

  public init(_ container: XMLContainer) throws {
    try self.init(container.element)
  }

}

public struct XMLContainer: DataContainerProtocol {

  let element: AEXMLElement
  let document: AEXMLDocument

  init(element: AEXMLElement, document: AEXMLDocument) {
    self.element = element
    self.document = document
  }

  public typealias Iterator = GenericDataContainerIterator<XMLContainer>

  public static func container(with data: Data, at path: String?) throws -> XMLContainer {
    let xml = try AEXMLDocument(xml: data)

    if let path = path {
      let xpathed = xml.xpath(path)
      if let error = xpathed.error {
        throw Gnomon.Error.unableToParseModel(error)
      }

      return self.init(element: xpathed, document: xml)
    } else {
      return self.init(element: xml.root, document: xml)
    }
  }

  public func multiple() -> GenericDataContainerIterator<XMLContainer>? {
    if let array = element.all {
      return .init(array.map { XMLContainer(element: $0, document: document) })
    } else {
      return nil
    }
  }

  public static func empty() -> XMLContainer {
    return self.init(element: AEXMLElement(name: ""), document: AEXMLDocument())
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
