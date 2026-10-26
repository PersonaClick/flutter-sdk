#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'personaclick_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin wrapper around PersonaClick native SDK.'
  s.description      = <<-DESC
Flutter plugin wrapper around PersonaClick native SDK.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PersonaClick' => 'support@personaclick.com' }
  s.source           = { :path => '.' }
  # The sources live where Swift Package Manager expects them (personaclick_sdk/Package.swift);
  # CocoaPods builds the same files.
  s.source_files = 'personaclick_sdk/Sources/personaclick_sdk/**/*.swift'
  s.resource_bundles = {'personaclick_sdk_privacy' => ['personaclick_sdk/Sources/personaclick_sdk/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  # Keep in step with the dependency in personaclick_sdk/Package.swift. CocoaPods trunk is
  # read-only, so a version newer than the last one there resolves only through the
  # app's Podfile (see "iOS" in README.md).
  s.dependency 'PersonaClick', '3.36.1'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end

