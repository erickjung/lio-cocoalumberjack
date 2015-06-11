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

        NSLog(@"[log.io] connecting to %@:%d", self.host, self.port);

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
        [self sendRequest:[NSString stringWithFormat:@"+log|%@|%@|%d|%@ %@\r\n", self.streamList[@(logMessage->_flag)],
                                                     self.nodeName,
                                                     logMessage->_flag,
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
}

@end