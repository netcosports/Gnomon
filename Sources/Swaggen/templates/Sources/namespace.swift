{% include "Includes/Header.stencil" enum %}

public enum {{ options.name }} {

    public static var baseUrlString = "{{ servers[0].url|default:"" }}"
    public static var requestInterceptor: ((URLRequest, SecurityRequirement?) -> URLRequest)?

    {% for tag in tags %}
    public enum {{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }} {}
    {% endfor %}
}
