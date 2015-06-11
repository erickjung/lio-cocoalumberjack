#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "GCDAsyncSocket.h"

@interface LIOLogger : DDAbstractLogger <DDLogger, GCDAsyncSocketDelegate>

+ (instancetype) sharedInstance;

@property (nonatomic, copy) NSString *nodeName;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSUInteger port;

@end