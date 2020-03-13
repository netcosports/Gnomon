{% include "Includes/Header.stencil" enum %}
import Gnomon

public enum {{ options.name }}: DateDecoderProvider {

    public static var baseUrlString = "{{ servers[0].url|default:"" }}"
    public static var requestInterceptor: ((URLRequest, SecurityRequirement?) -> URLRequest)?
    public static var dateDecoder: ((Decoder) throws -> Date)?

    {% for tag in tags %}
    public enum {{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }} {}
    {% endfor %}
}
