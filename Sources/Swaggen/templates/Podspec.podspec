Pod::Spec.new do |s|
    s.source_files = '*.swift'
    s.name = '{{ options.name }}'
    s.authors = '{{ options.authors|default:"Yonas Kolb" }}'
    s.summary = '{% if info.description == "" %}A generated API{% else %}{{ info.description|default:"A generated API" }}{% endif %}'
    s.version = '{% if info.version == "" %}0.1{% else %}{{ info.version|default:"0.1"|replace:"v","" }}{% endif %}'
    s.homepage = '{{ options.homepage|default:"https://github.com/yonaskolb/SwagGen" }}'
    s.source = { :git => 'git@github.com:https://github.com/yonaskolb/SwagGen.git' }
    s.ios.deployment_target = '9.0'
    s.tvos.deployment_target = '9.0'
    s.osx.deployment_target = '10.9'
    s.source_files = 'Sources/**/*.swift'
    {% for dependency in options.dependencies %}
    s.dependency '{{ dependency.pod }}' {% if dependency.version %}, '{{ dependency.version }}' {% endif %}
    {% endfor %}
end
