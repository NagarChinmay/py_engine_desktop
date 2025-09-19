#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint py_engine_desktop.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'py_engine_desktop'
  s.version          = '1.0.0'
  s.summary          = '🐍 Flutter plugin for embedded Python runtime - Execute scripts, REPL, pip packages on desktop.'
  s.description      = <<-DESC
The ultimate Flutter plugin for embedded Python scripting and automation on desktop platforms. 
Seamlessly integrate Python interpreter, execute scripts, run interactive REPL sessions, and manage packages.
Perfect for data science apps, automation tools, machine learning integrations, and educational platforms.
Cross-platform support for Windows, macOS, and Linux with zero-configuration setup.
                       DESC
  s.homepage         = 'https://github.com/NagarChinmay/py_engine_desktop'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chinmay Nagar' => 'nagar.chinmay.dev@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'py_engine_desktop_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
