source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Tests' do
  pod 'SwiftLint'
  pod 'Gnomon/Core', :path => '.'
  pod 'Gnomon/JSON', :path => '.'
  pod 'Gnomon/XML', :path => '.'
  pod 'Nimble', '~> 7.0'
  pod 'RxBlocking', '4.0.0-rc.0'

  target 'iOSTests' do 
    platform :ios, '8.0'
  end

  target 'tvOSTests' do
    platform :tvos, '9.0'
  end

  target 'macOSTests' do
    platform :osx, '10.10'
  end
end
