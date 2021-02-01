//
//  LLCallToActionEmitter.m
//  LLLocalytics
//

#import "LLCallToActionEmitter.h"

// Only support one Emitter registeration.
static LLCallToActionEmitter *emitter;

@interface LLCallToActionEmitter ()
@end

@implementation LLCallToActionEmitter
RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        emitter = self;
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"localyticsShouldDeeplink",
            @"localyticsDidOptOut",
            @"localyticsDidPrivacyOptOut",
            @"localyticsShouldPromptForLocationWhenInUsePermissions",
            @"localyticsShouldPromptForLocationAlwaysPermissions",
            @"localyticsShouldPromptForNotificationPermissions"
            ];
}

/**
 send event which are non blocking.

 @param eventName Event Name ex., localyticsDidDisplayInAppMessage
 @param data NSDictionary with key values appropriate to the event
 */
+ (void)sendEvent:(NSString*)eventName withData:(id)data {
    if (emitter && emitter.isObserved) {
        [emitter sendEventWithName:eventName body:data];
    }
}

@end

