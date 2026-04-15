#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint atomic_transact_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'atomic_transact_flutter'
  s.version          = '3.13.4'
  s.summary          = 'Atomic Flutter SDK'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://docs.atomicfi.com/reference/transact-sdk#libraries__flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sean Hill' => 'sean@atomicfi.com' }
  s.source           = { :path => '.' }
  s.source_files = 'atomic_transact_flutter/Sources/atomic_transact_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Vendored iOS frameworks (CocoaPods fallback when SPM is not available)
  s.vendored_frameworks = [
    "frameworks/AtomicTransact.xcframework",
    "frameworks/MuppetIOS.xcframework",
    "frameworks/QuantumIOS.xcframework"
  ]

end
