
Pod::Spec.new do |s|
  s.name             = 'curl'
  s.version          = '8.1.2'
  s.summary          = 'libcurl ios amd mac library '
  s.homepage         = 'https://github.com/zhtut/curl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ztgtut' => 'ztgtut@github.com' }
  s.source           = { :git => 'https://github.com/zhtut/curl.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.13'

  #  s.source_files = 'curl/include/**/*.h'
  #   s.osx.vendored_libraries = 'curl/lib/*_Mac.a'
  #  s.ios.vendored_libraries = 'curl/lib/*.a'
  
  s.library = 'z'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.vendored_frameworks = 'curl.xcframework'
  
end
