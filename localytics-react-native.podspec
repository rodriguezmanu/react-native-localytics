require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = package['name']
  s.version        = package['version']
  s.description    = package['description']
  s.summary        = package['summary']
  s.homepage       = package['homepage']
  s.author         = package['author']
  s.license        = package['license']
  s.source         = { :git => 'https://github.com/localytics/react-native-template-app.git', :tag => "v#{s.version}" }
  s.requires_arc   = true
  s.platform       = :ios, '9.0'
  s.source_files   = 'ios/*.{h,m}', 'ios/PluginLibrary/*.{h,m}'
  s.ios.vendored_frameworks = 'ios/Frameworks/Localytics.xcframework'
  s.dependency     'React'
end
