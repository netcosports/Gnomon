import Foundation
#if SWIFT_PACKAGE
  import Gnomon
#endif

public struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {

    private let string: String
    private let int: Int?

    public var stringValue: String { return string }

    public init(string: String) {
        self.string = string
        int = nil
    }
    public init?(stringValue: String) {
        string = stringValue
        int = nil
    }

    public var intValue: Int? { return int }
    public init?(intValue: Int) {
        string = String(describing: intValue)
        int = intValue
    }

    public init(stringLiteral value: String) {
        string = value
        int = nil
    }
}

public extension KeyedDecodingContainer {
    func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
        return try decode(T.self, forKey: key)
    }
    
    func decodeIfPresent<T>(_ key: KeyedDecodingContainer.Key) throws -> T? where T: Decodable {
        #if DEBUG
        return try decodeIfPresent(T.self, forKey: key)
        #else
        return try? decode(T.self, forKey: key)
        #endif
    }
}

extension Dictionary: BaseModel, DecodableModel where Key: Decodable, Value: Decodable {
}
