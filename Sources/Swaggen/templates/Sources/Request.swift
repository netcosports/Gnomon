{% include "Includes/Header.stencil" %}

import Foundation
import Gnomon
import RxSwift

extension {{ options.name }}{% if tag %}.{{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }}{% endif %} {
    {% for enum in requestEnums %}

    {% if not enum.isGlobal %}

    {% filter indent:4 %}{% include "Includes/Enum.stencil" enum %}{% endfilter %}
    {% endif %}
    {% endfor %}

    {% if description and summary %}
    {% if description == summary %}
    /** {{ description }} */
    {% else %}
    /**
    {{ summary }}

    {{ description }}
    */
    {% endif %}
    {% else %}
    {% if description %}
    /** {{ description }} */
    {% endif %}
    {% if summary %}
    /** {{ summary }} */
    {% endif %}
    {% endif %}
    public static func {{ type|lowerCamelCase }}(
        {% if body %}{{ body.name }}: {{ body.optionalType }}{% if nonBodyParams %},{% endif %}{% endif %}
        {% for param in nonBodyParams %}
        {{param.name}}: {{param.optionalType}}{% ifnot param.required %} = nil{% endif %}{% ifnot forloop.last %}, {% endif %}
        {% endfor %}
    ) throws -> Request<{{ successType|default:"String"}}> {
        guard var urlComonents = URLComponents(string: {{ options.name }}.baseUrlString) else {
            throw "Failed to create url components from: \({{ options.name }}.baseUrlString)"
        }
        urlComonents.path += "{{ path }}"
        {% if 0 != pathParams.count %}
        {% for param in pathParams %}
            .replacingOccurrences(of: "{" + "{{ param.value }}" + "}", with: "\({{ param.name }})")
        {% endfor %}

        {% endif %}
        {# append query parameters #}
        {% if queryParams%}

        var queryItems = [URLQueryItem]()

        {% for param in queryParams %}
        {% if param.optional %}
        if let {{ param.name }} = {{ param.name }} {
            {% filter indent:4 %}{% include "Includes/AppendQueryItem.stencil" %}{% endfilter %}
        }
        {% else %}
        {% filter indent:4 %}{% include "Includes/AppendQueryItem.stencil" %}{% endfilter %}
        {% endif %}
        {% endfor %}

        urlComonents.queryItems = queryItems
        urlComonents.percentEncodedQuery = urlComonents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

        {% endif %}
        {# end append query parameters #}
        {# append headers #}
        {% if headerParams %}
        var headers = [String: String]()
        {% for param in headerParams %}
        {% if param.optional %}
        if let {{ param.name }} = {{ param.name }} {
            headers["{{ param.value }}"] = {% if param.type == "String" %}{{ param.name }}{% else %}String(describing: {{ param.name }}){% endif %}
        }
        {% else %}
        headers["{{ param.value }}"] = {% if param.type == "String" %}options.{{ param.name }}{% else %}String(describing: options.{{ param.name }}){% endif %}
        {% endif %}
        {% endfor %}
        {% endif %}
        {# append url encoded body parameters #}
        {% if formProperties %}
        var urlParams = [String: Any]()
        {% for param in formProperties %}
        {% if param.optional %}
        if let {{ param.name }} = {{ param.name }} {
            urlParams["{{ param.value }}"] = ({{ param.name }})
        }
        {% else %}
        urlParams["{{ param.value }}"] = {{ param.name }}
        {% endif %}
        {% endfor %}

        {% endif %}
        {# end append url encoded body parameters #}
        guard let requestURL = urlComonents.url else {
            throw "Failed to create url from components \(urlComonents)"
        }
        let request = Request<{{ successType|default:"String"}}>(url: requestURL)
            .setMethod(.{{ method|uppercase }})
            {% if body %}
            .setParams(.data(try JSONEncoder().encode({{ body.name }}), contentType: "application/json"))
            {% endif %}
            {% if headerParams %}
            .setHeaders(headers)
            {% endif %}
            {% if formProperties %}
            .setParams(.urlEncoded(urlParams))
            {% endif %}

        if let requestInterceptor = {{ options.name }}.requestInterceptor {
            request.setAsyncInterceptor({{ options.interceptorExlusive|default: false }}) { (urlRequest: URLRequest) -> Observable<URLRequest> in
                return requestInterceptor(
                    urlRequest,
                    {% if not securityRequirement %}nil{% else %}SecurityRequirement(type: "{{ securityRequirement.name }}", scopes: [{% for scope in securityRequirement.scopes %}"{{ scope }}"{% ifnot forloop.last %}, {% endif %}{% endfor %}]){% endif %}
                )
            }
        }
        
        return request
    }
}
