require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "apptrace-react-native"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  apptrace-react-native
                   DESC
  s.homepage     = "https://www.apptrace.cn/"
  # brief license entry:
  s.license      = "MIT"
  # optional - use expanded license entry instead:
  # s.license    = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Apptrace" => "dev@apptrace.cn" }
  s.platforms    = { :ios => "11.0" }
  s.source       = { :git => "https://github.com/apptrace/apptrace-react-native.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,c,m,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency 'ApptraceSDK', "~> 1.1.8"
end

