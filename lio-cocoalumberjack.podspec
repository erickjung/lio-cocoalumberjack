Pod::Spec.new do |s|
  s.name         = "lio-cocoalumberjack"
  s.version      = "1.0.0"
  s.summary      = "A log.io logger appender for cocoalumberjack."

  s.description  = <<-DESC
                   A log.io logger appender for cocoalumberjack.

                   - [log.io](http://logio.org/) website
                   - [cocoalumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) website
                   DESC

  s.homepage     = "https://github.com/erickjung/lio-cocoalumberjack"
  s.license      = "MIT"
  s.author       = { "Erick Jung" => "erickjung@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "5.0"
  s.source       = { :git => "https://github.com/erickjung/lio-cocoalumberjack.git", :tag => "1.0.0" }
  s.source_files  = "Classes"
  s.requires_arc = true
  
  s.dependency "CocoaLumberjack"
  s.dependency "CocoaAsyncSocket"
end
