#
# Be sure to run `pod lib lint XML2Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XML2Swift'
  s.version          = '0.1.0'
  s.summary          = 'A short description of XML2Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Igor Kotkovets/XML2Swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Igor Kotkovets' => 'igorkotkovets@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/Igor Kotkovets/XML2Swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.preserve_paths = 'XML2Swift/libxml2/*'
  s.source_files = 'XML2Swift/Classes/**/*.swift'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.2' }
  s.library = "xml2"
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2', 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/XML2Swift/libxml2' }
end
