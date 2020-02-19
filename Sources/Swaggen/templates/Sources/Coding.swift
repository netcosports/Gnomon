{% include "Includes/Header.stencil" %}

{% for type, typealias in options.typeAliases %}
public typealias {{ type }} = {{ typealias }}
{% endfor %}
