
Pod::Spec.new do |s|
  s.name             = 'curl'
  s.version          = '7.80.0'
  s.summary          = 'libcurl ios library '
  s.homepage         = 'https://github.com/zhtut/curl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ztgtut' => 'ztgtut@github.com' }
  s.source           = { :git => 'https://github.com/zhtut/curl.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'curl/include/*.h'
  s.vendored_libraries = 'curl/lib/*.a'
  s.ios.library = 'z'
  
end
