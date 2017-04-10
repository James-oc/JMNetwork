Pod::Spec.new do |s|

  s.name          = "JMNetwork"
  s.version       = "1.0.3"
  s.license       = "MIT"
  s.summary       = "JMNetwork is a request util based on AFNetworking."
  s.homepage      = "https://github.com/James-oc/JMNetwork"
  s.author        = { "xiaobs" => "1007785739@qq.com" }
  s.source        = { :git => "https://github.com/James-oc/JMNetwork.git", :tag => "1.0.3" }
  s.requires_arc  = true
  s.source_files  = "JMNetwork/*.{h,m}"
  s.private_header_files = "JMNetwork/JMNetworkPrivate.h"
  s.platform      = :ios, '8.0'
  s.framework     = 'CFNetwork'  
  s.dependency "AFNetworking", "~> 3.1.0"

end
