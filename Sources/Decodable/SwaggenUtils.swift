import Foundation
#if SWIFT_PACKAGE
  import Gnomon
#endif

public struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {

    private let string: String
    private let int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
        int = nil
    }
    init?(stringValue: String) {
        string = stringValue
        int = nil
    }

    var intValue: Int? { return int }
    init?(intValue: Int) {
        string = String(describing: intValue)
        int = intValue
    }

    init(stringLiteral value: String) {
        string = value
        int = nil
    }
}

public extension KeyedDecodingContainer {
    func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
        return try decode(T.self, forKey: key)
    }
    
    func decodeIfPresent<T>(_ key: KeyedDecodingContainer.Key) throws -> T? where T: Decodable {
        return try decodeIfPresent(T.self, forKey: key)
    }
}

public extension Dictionary: BaseModel, DecodableModel where Key: Decodable, Value: Decodable {
}
