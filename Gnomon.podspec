Pod::Spec.new do |s|
  s.name = "Gnomon"
  s.version = "2.0.1"
  s.summary = "Common Rest API manager for Netco Sports projects on Swift with RxSwift"

  s.license = { :type => "MIT" }
  s.homepage = "https://github.com/netcosports/Gnomon"
  s.author = {
    "Vladimir Burdukov" => "vladimir.burdukov@netcosports.com"
  }
  s.source = { :git => "https://github.com/netcosports/Gnomon.git", :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.source_files = 'Sources/*.swift'

  s.dependency 'RxSwift', '~> 3'
  s.dependency 'SwiftyJSON', '~> 3'
  s.dependency 'AEXML', '~> 4'
  s.dependency 'FormatterKit/URLRequestFormatter', '>= 1.8.2'
end
