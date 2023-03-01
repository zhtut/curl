
Pod::Spec.new do |s|
  s.name             = 'curl'
  s.version          = '7.88.1'
  s.summary          = 'libcurl ios library '
  s.homepage         = 'https://github.com/zhtut/curl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ztgtut' => 'ztgtut@github.com' }
  s.source           = { :git => 'https://github.com/zhtut/curl.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'

  # s.source_files = 'curl/include/*.h'
  # s.osx.vendored_libraries = 'curl/lib/*_Mac.a'
  # s.ios.vendored_libraries = 'curl/lib/*_iOS.a'
  # s.library = 'z'

  s.vendored_frameworks = 'curl.xcframework'
  
end
