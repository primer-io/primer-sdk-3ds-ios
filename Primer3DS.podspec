Pod::Spec.new do |s|
  s.name             = 'Primer3DS'
  s.version          = '2.4.3'
  s.summary          = 'A wrapper for the 3DS SDK.'

  s.description      = <<-DESC
A wrapper around the 3rd party 3DS SDK.
                       DESC

  s.homepage         = 'https://primer.io/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Primer' => 'dx@primer.io' }
  s.source           = { :git => 'https://github.com/primer-io/primer-sdk-3ds-ios.git', :tag => s.version.to_s }

  s.swift_version = '5'
  s.ios.deployment_target = '13.0'
  
  s.ios.source_files = 'Sources/Primer3DS/Classes/*.{swift}'
  s.ios.frameworks  = 'Foundation', 'UIKit'
  s.ios.vendored_frameworks = 'Sources/Frameworks/ThreeDS_SDK.xcframework'
  s.ios.pod_target_xcconfig = { "BUILD_LIBRARY_FOR_DISTRIBUTION" => 'YES' }
  s.xcconfig = { 'OTHER_SWIFT_FLAGS' => '-no-verify-emitted-module-interface' }
end
