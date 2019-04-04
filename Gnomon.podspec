Pod::Spec.new do |s|
  s.name = "Gnomon"
  s.version = "4.2"
  s.summary = "Common Rest API manager for Netco Sports projects on Swift with RxSwift"
  s.swift_version = "5.0"

  s.license = { :type => "MIT" }
  s.homepage = "https://github.com/netcosports/Gnomon"
  s.author = {
    "Vladimir Burdukov" => "vladimir.burdukov@netcosports.com"
  }
  s.source = { :git => "https://github.com/netcosports/Gnomon.git", :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.default_subspec = 'JSON'

  s.subspec 'Core' do |sub|
    sub.source_files = 'Sources/Core/*.swift'
    sub.dependency 'RxSwift', '~> 4.2'
    sub.dependency 'FormatterKit/URLRequestFormatter', '>= 1.8.2'
  end

  s.subspec 'Decodable' do |sub|
    sub.source_files = 'Sources/Decodable/*.swift'
    sub.dependency 'Gnomon/Core'
  end

  s.subspec 'JSON' do |sub|
    sub.source_files = 'Sources/JSON/*.swift'
    sub.dependency 'SwiftyJSON', '~> 4.2'
    sub.dependency 'Gnomon/Core'
  end

  s.subspec 'XML' do |sub|
    sub.source_files = 'Sources/XML/*.swift'
    sub.dependency 'AEXML', '~> 4.2'
    sub.dependency 'Gnomon/Core'
  end
end
