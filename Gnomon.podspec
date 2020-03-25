Pod::Spec.new do |s|
  s.name = "Gnomon"
  s.version = "5.2.2"
  s.summary = "Common Rest API manager for Netco Sports projects on Swift with RxSwift"

  s.license = { :type => "MIT" }
  s.homepage = "https://github.com/netcosports/Gnomon"
  s.author = {
    "Vladimir Burdukov" => "vladimir.burdukov@netcosports.com"
  }
  s.source = { :git => "https://github.com/netcosports/Gnomon.git", :tag => s.version.to_s }
  s.ios.deployment_target = "9.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"

  s.default_subspec = "JSON"

  s.swift_versions = ['5.0', '5.1']

  s.subspec "Core" do |sub|
    sub.source_files = "Sources/Core/*.swift"
    sub.dependency "RxSwift", "~> 5"
  end

  s.subspec "Decodable" do |sub|
    sub.source_files = "Sources/Decodable/*.swift"
    sub.dependency "Gnomon/Core"
  end

  s.subspec "JSON" do |sub|
    sub.source_files = "Sources/JSON/*.swift"
    sub.dependency "SwiftyJSON", "~> 5"
    sub.dependency "Gnomon/Core"
  end

  s.subspec "XML" do |sub|
    sub.source_files = "Sources/XML/*.swift"
    sub.dependency "AEXML", "~> 4.2"
    sub.dependency "Gnomon/Core"
  end
end
