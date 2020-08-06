{% include "Includes/Header.stencil" enum %}
import Gnomon
import RxSwift

public enum {{ options.name }}: DateDecoderProvider, DateEncoderProvider {

    public static var baseUrlString = "{{ servers[0].url|default:"" }}"
    public static var requestInterceptor: ((URLRequest, SecurityRequirement?) -> Observable<URLRequest>)?
    public static var dateDecoder: ((Decoder) throws -> Date)?
    public static var dateEncoder: ((Date, Encoder) throws -> ())?
    public static var dateSerializer: ((Date) throws -> String)?

    {% for tag in tags %}
    public enum {{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }} {}
    {% endfor %}
}

let defaultDateSerializer: (Date) throws -> String = { date in
    let formatterWithoutMilliseconds = DateFormatter()
    formatterWithoutMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatterWithoutMilliseconds.locale = Locale(identifier: "en_US_POSIX")
    formatterWithoutMilliseconds.timeZone = TimeZone(identifier: "UTC")
    return formatterWithoutMilliseconds.string(from: date)
}
