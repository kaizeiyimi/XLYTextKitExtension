Pod::Spec.new do |s|
  s.name         = "XLYTextKitExtension"
  s.version      = "1.2"
  s.summary      = "simple extension of TextKit for adding views and custom drawings."
  s.homepage     = "https://github.com/kaizeiyimi/XLYTextKitExtension"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "kaizei" => "kaizeiyimi@126.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/kaizeiyimi/XLYTextKitExtension.git", :tag => '1.2' }
  
  s.source_files  = "XLYTextKitExtension/codes/**/*.swift"
  s.requires_arc = true
end

