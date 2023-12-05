
Pod::Spec.new do |s|
  s.name             = 'curl'
  s.version          = '8.4.0'
  s.summary          = 'libcurl ios amd mac xcframework'
  s.homepage         = 'https://github.com/zhtut/curl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ztgtut' => 'ztgtut@github.com' }
  s.source           = { :git => 'https://github.com/zhtut/curl.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '4.0'
  s.osx.deployment_target = '10.13'
  
  s.library = 'z'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.vendored_frameworks = 'curl.xcframework'
  
end
