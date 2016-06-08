// Copyright (c) 2015 Erick Jung
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LIOLogger.h"

@interface LIOLogger ()

@property (nonatomic, assign) BOOL wasInitialized;
@property (nonatomic, assign) NSUInteger calendarUnitFlags;
@property (nonatomic, strong) NSDictionary *streamList;
@property (nonatomic, strong) GCDAsyncSocket *tcpSocket;


@end

@implementation LIOLogger

#pragma mark - init methods

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken = 0;
    static id _sharedInstance = nil;

    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (NSString *) loggerName {
    return @"cocoa.lumberjack.liologger";
}

- (BOOL) initialize {

    if (!self.wasInitialized) {
        self.calendarUnitFlags = (NSCalendarUnitYear   |
                NSCalendarUnitMonth  |
                NSCalendarUnitDay    |
                NSCalendarUnitHour   |
                NSCalendarUnitMinute |
                NSCalendarUnitSecond);

        self.streamList = @{
                @(DDLogFlagError)   : @"error",
                @(DDLogFlagWarning) : @"warn",
                @(DDLogFlagInfo)    : @"info",
                @(DDLogFlagDebug)   : @"debug",
                @(DDLogFlagVerbose) : @"verbose",
        };

        NSLog(@"[log.io] connecting to %@:%ld", self.host, (long) self.port);

        self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error = nil;
        if ([self.tcpSocket connectToHost:self.host onPort:(uint16_t) self.port error:&error]) {

            for (NSString *key in self.streamList) {
                [self sendRequest:[NSString stringWithFormat:@"+node|%@|%@\r\n", self.nodeName, self.streamList[key]]];
            }

            self.wasInitialized = YES;
        } else {
            NSLog(@"[log.io] could not connect %@", error);
        }
    }

    return self.wasInitialized;
}

#pragma mark - logging methods

- (void) sendRequest:(NSString *)msg {
    [self.tcpSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
}

- (NSString *) getMessageDateTimeString:(DDLogMessage *)logMessage {
    NSDateComponents *components = [[NSCalendar autoupdatingCurrentCalendar] components:(NSCalendarUnit) self.calendarUnitFlags fromDate:logMessage->_timestamp];
    NSTimeInterval epoch = [logMessage->_timestamp timeIntervalSinceReferenceDate];
    int milliseconds = (int) ((epoch - floor(epoch)) * 1000);

    return [NSString stringWithFormat:@"%04ld-%02ld-%02ld %02ld:%02ld:%02ld:%03d",
                                      (long) components.year,
                                      (long) components.month,
                                      (long) components.day,
                                      (long) components.hour,
                                      (long) components.minute,
                                      (long) components.second,
                                      milliseconds];
}

- (void) logMessage:(DDLogMessage *)logMessage {

    if (![self initialize]) {
        NSLog(@"[log.io] not initialized!");
        return;
    }

    if (logMessage && self.streamList[@(logMessage->_flag)] != nil) {
        NSString *message = _logFormatter ? [_logFormatter formatLogMessage:logMessage] : logMessage->_message;
        [self sendRequest:[NSString stringWithFormat:@"+log|%@|%@|%ld|%@ %@\r\n", self.streamList[@(logMessage->_flag)],
                                                     self.nodeName,
                                                     (long) logMessage->_flag,
                                                     [self getMessageDateTimeString:logMessage],
                                                     message]];
    }
}

#pragma mark - gcd methods

- (void) socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"[log.io] socket connected on host!");
}

- (void) socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"[log.io] socket secured on host!");
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"[log.io] socket disconnected from host: (%@)", err);
    self.wasInitialized = NO;
}

@end