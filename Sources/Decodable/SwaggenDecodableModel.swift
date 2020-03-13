let dateDecoder: (Decoder) throws -> Date = { decoder in
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)

    let formatterWithMilliseconds = DateFormatter()
    formatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatterWithMilliseconds.locale = Locale(identifier: "en_US_POSIX")
    formatterWithMilliseconds.timeZone = TimeZone(identifier: "UTC")

    let formatterWithoutMilliseconds = DateFormatter()
    formatterWithoutMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatterWithoutMilliseconds.locale = Locale(identifier: "en_US_POSIX")
    formatterWithoutMilliseconds.timeZone = TimeZone(identifier: "UTC")

    guard let date = formatterWithMilliseconds.date(from: string) ??
        formatterWithoutMilliseconds.date(from: string) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Could not decode date")
    }
    return date
}

public protocol DateDecoderProvider {
    static var dateDecoder: ((Decoder) throws -> Date)? { get }
}

public protocol SwaggenDecodableModel: DecodableModel {
    associatedtype ModelDateDecoderProvider: DateDecoderProvider
}

extension SwaggenDecodableModel {
    public static var decoder: JSONDecoder {
      let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom(ModelDateDecoderProvider.dateDecoder ?? dateDecoder)
      return jsonDecoder
    }
}
