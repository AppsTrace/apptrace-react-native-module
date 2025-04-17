#import "ApptraceModule.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTEventEmitter.h>
#elif __has_include("RCTBridge.h")
#import "RCTBridge.h"
#import "RCTLog.h"
#import "RCTEventEmitter.h"
#elif __has_include("React/RCTBridge.h")
#import "React/RCTBridge.h"
#import "React/RCTLog.h"
#import "React/RCTEventEmitter.h"
#endif

static NSUserActivity *cacheUserActivity = nil;

@interface ApptraceModule ()

@property (nonatomic, strong) NSDictionary *wakeUpTraceDict;
@property (nonatomic, assign) BOOL hasRegisterWakeUp;
@property (nonatomic, assign) BOOL hasInit;

@end

@implementation ApptraceModule

static NSString * const kCode = @"code";
static NSString * const kMsg = @"msg";
static NSString * const kParamsData = @"paramsData";

static NSString * const ApptraceWakeUpEvent = @"ApptraceWakeUpEvent";

RCT_EXPORT_MODULE(ApptraceModule)

static ApptraceModule *sharedInstance = nil;

- (instancetype)init {
    if (self = [super init]) {
        sharedInstance = self;
    }
    return self;
}

+ (ApptraceModule *)shared {
    return sharedInstance;
}

#pragma mark - Public

+ (BOOL)handleUniversalLink:(NSUserActivity * _Nullable)userActivity {
    ApptraceModule *module = [ApptraceModule shared];
    
    if (module.hasInit) {
        return [Apptrace handleUniversalLink:userActivity];
    } else {
        cacheUserActivity = userActivity;
        
        return NO;
    }
}

#pragma mark - React Native

- (NSArray<NSString *> *)supportedEvents {
    return @[ApptraceWakeUpEvent];
}

RCT_EXPORT_METHOD(initSDK:(BOOL)enableClipboard) {
    ApptraceModule *module = [ApptraceModule shared];
    
    if (module.hasInit) {
        return;
    }
    
    if (!enableClipboard) {
        [Apptrace disableClipboard];
    }
    
    module.hasInit = YES;
    [Apptrace initWithDelegate:module];
    
    if (cacheUserActivity) {
        [ApptraceModule handleUniversalLink:cacheUserActivity];
        
        cacheUserActivity = nil;
    }
}

RCT_EXPORT_METHOD(getInstall:(RCTResponseSenderBlock)callback)
{
    ApptraceModule *module = [ApptraceModule shared];
    
    [Apptrace getInstall:^(AppInfo * _Nullable appData) {
        if (appData == nil) {
            NSDictionary *dict = [ApptraceModule _parseToResultDict:-1 msg:@"Extract data fail." paramsData:@""];
            [module _dispatchEventToScript:callback result:dict];
            
            return;
        }

        NSDictionary *dict = [ApptraceModule _parseToResultDict:200 msg:@"Success" paramsData:appData.paramsData];
        
        [module _dispatchEventToScript:callback result:dict];
    } fail:^(NSInteger code, NSString * _Nonnull message) {
        NSDictionary *dict = [ApptraceModule _parseToResultDict:code msg:message paramsData:@"" ];
        
        [module _dispatchEventToScript:callback result:dict];
    }];
}

RCT_EXPORT_METHOD(registerWakeUp:(RCTResponseSenderBlock)callback)
{
    ApptraceModule *module = [ApptraceModule shared];
    
    module.hasRegisterWakeUp = YES;
    
    if (module.wakeUpTraceDict.count > 0) {
        [module _dispatchEventToScript:callback result:module.wakeUpTraceDict];
        
        module.wakeUpTraceDict = nil;
    }
}

#pragma mark - Private

+ (NSDictionary *)_parseToResultDict:(NSInteger)code
                                 msg:(NSString *)msg
                          paramsData:(NSString *)paramsData {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[kCode] = @(code);
    dict[kMsg] = msg ?: @"";
    dict[kParamsData] = paramsData ?: @"";
    
    return dict;
}

- (void)_dispatchEventToScript:(RCTResponseSenderBlock)callback result:(NSDictionary *)result {
    if (!callback) {
        [self sendEventWithName:ApptraceWakeUpEvent body:result];
    } else {
        callback(@[result]);
    }
}

#pragma mark - ApptraceDelegate

- (void)handleWakeUp:(AppInfo *)appData {
    if (appData == nil) {
        return;
    }
    
    NSDictionary *dict = [ApptraceModule _parseToResultDict:200 msg:@"Success" paramsData:appData.paramsData];
        
    if (self.hasRegisterWakeUp) {
        [self _dispatchEventToScript:nil result:dict];
        
        self.wakeUpTraceDict = nil;
    } else {
        self.wakeUpTraceDict = dict;
    }
}

@end
