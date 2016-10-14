#
# Be sure to run `pod lib lint KRClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KRClient'
  s.version          = '0.5.0'
  s.summary          = 'A light-weight yet powerful network client.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
KRClient is an easy-to-use yet powerful networking library.
Some key features include data validating, serialized URL requests where the requests can take advatange of the returned data from the previous requests.
                       DESC

  s.homepage         = 'https://github.com/BridgeTheGap/KRClient'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Josh Woomin Park' => 'wmpark@knowre.com' }
  s.source           = { :git => 'https://github.com/BridgeTheGap/KRClient.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'KRClient/Classes/**/*'
  
  # s.resource_bundles = {
  #   'KRClient' => ['KRClient/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
