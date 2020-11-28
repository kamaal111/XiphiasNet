Pod::Spec.new do |spec|

  spec.name         = "XiphiasNet"
  spec.version      = "3.0.3"
  spec.summary      = "A simple network layer"

  spec.description  = <<-DESC
This CocoaPods library is a simple network layer.
                   DESC

  spec.homepage     = "https://github.com/kamaal111/XiphiasNet"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "kamaal111" => "kamaal.f1@gmail.com" }

  spec.ios.deployment_target = "11.0"
  spec.swift_version = "5.2"

  spec.source        = { :git => "https://github.com/kamaal111/XiphiasNet.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/XiphiasNet/**/*.{h,m,swift}"

end