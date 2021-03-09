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

let dateEncoder: (Date, Encoder) throws -> Void = { date, encoder in
  var container = encoder.singleValueContainer()

  let formatterWithoutMilliseconds = DateFormatter()
  formatterWithoutMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatterWithoutMilliseconds.locale = Locale(identifier: "en_US_POSIX")
  formatterWithoutMilliseconds.timeZone = TimeZone(identifier: "UTC")

  let string = formatterWithoutMilliseconds.string(from: date)

  try container.encode(string)
}

public protocol DateDecoderProvider {
  static var dateDecoder: ((Decoder) throws -> Date)? { get }
}

public protocol DateEncoderProvider {
  static var dateEncoder: ((Date, Encoder) throws -> Void)? { get }
}

public protocol EncodableModel {

  static var encoder: JSONEncoder { get }
}

public extension EncodableModel {

  static var encoder: JSONEncoder { JSONEncoder() }
}

public protocol SwaggenDecodableModel: DecodableModel, EncodableModel {
  associatedtype ModelDateDecoderProvider: DateDecoderProvider
  associatedtype ModelDateEncoderProvider: DateEncoderProvider
}

extension SwaggenDecodableModel {
  public static var encoder: JSONEncoder {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dateEncodingStrategy = .custom(ModelDateEncoderProvider.dateEncoder ?? dateEncoder)
    return jsonEncoder
  }

  public static var decoder: JSONDecoder {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .custom(ModelDateDecoderProvider.dateDecoder ?? dateDecoder)
    return jsonDecoder
  }
}
