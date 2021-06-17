source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Tests' do
  pod 'SwiftLint', '~> 0.27'
  pod 'Gnomon/Core', :path => '.'
  pod 'Gnomon/JSON', :path => '.'
  pod 'Gnomon/XML', :path => '.'
  pod 'Gnomon/Decodable', :path => '.'
  pod 'Nimble', '~> 7.0'
  pod 'RxBlocking'

  target 'iOSTests' do
    platform :ios, '11.0'
  end

  target 'tvOSTests' do
    platform :tvos, '11.0'
  end

  target 'macOSTests' do
    platform :osx, '10.10'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) TEST'
    end
  end
end
