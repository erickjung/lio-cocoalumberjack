# lio-cocoalumberjack

[![CI Status](http://img.shields.io/travis/Erick Jung/lio-cocoalumberjack.svg?style=flat)](https://travis-ci.org/Erick Jung/lio-cocoalumberjack)
[![Version](https://img.shields.io/cocoapods/v/lio-cocoalumberjack.svg?style=flat)](http://cocoapods.org/pods/lio-cocoalumberjack)
[![License](https://img.shields.io/cocoapods/l/lio-cocoalumberjack.svg?style=flat)](http://cocoapods.org/pods/lio-cocoalumberjack)
[![Platform](https://img.shields.io/cocoapods/p/lio-cocoalumberjack.svg?style=flat)](http://cocoapods.org/pods/lio-cocoalumberjack)

A [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) logger for [log.io](http://logio.org/) service.

## Usage

To run the example project, clone the repo, and run `pod install`.

Configure the logger and parameters:

``` objective-c
LIOLogger *logio = [LIOLogger sharedInstance];
logio.nodeName = [[UIDevice currentDevice] name];
logio.host = @"localhost";
logio.port = 28777;
[DDLog addLogger:logio];
```

## Installation

lio-cocoalumberjack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "lio-cocoalumberjack"
```

## License

lio-cocoalumberjack is available under the MIT license. See the LICENSE file for more info.
