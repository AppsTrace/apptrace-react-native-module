#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#elif __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#elif __has_include("React/RCTBridgeModule.h")
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#endif

#import <Foundation/Foundation.h>
#import <ApptraceSDK/ApptraceSDK.h>

@interface ApptraceModule : RCTEventEmitter <ApptraceDelegate>

/**
 * 处理 Universal link 逻辑
 * @param userActivity 通过Universal link调起时，包含系统回调回来的URL信息的NSUserActivity
 * @return bool Apptrace是否成功识别该URL
 */
+ (BOOL)handleUniversalLink:(NSUserActivity * _Nullable)userActivity;

@end
