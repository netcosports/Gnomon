//
//  Created by Vladimir Burdukov on 23/02/2018.
//

public protocol StringModel: BaseModel where DataContainer == String {
  static var encoding: String.Encoding { get }
}

extension StringModel {

  public static func dataContainer(with data: Data, at path: String?) throws -> DataContainer {
    guard let string = String(data: data, encoding: encoding) else {
      throw "can't parse String with encoding \(encoding)"
    }
    return string
  }

}

extension String: DataContainerProtocol {

  public typealias Iterator = GenericDataContainerIterator<String>

  public static func container(with data: Data, at path: String?) throws -> String {
    throw "should be implemented in StringModel"
  }

  public func multiple() -> GenericDataContainerIterator<String>? {
    return .init(components(separatedBy: .newlines))
  }

  public static func empty() -> String {
    return ""
  }

}

extension String: StringModel {
  public static var encoding: String.Encoding { return .utf8 }
}
