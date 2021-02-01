//
//  LLMessagingEmitter.m
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/24/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "LLMessagingEmitter.h"

// Only support one Emitter registeration.
static LLMessagingEmitter *messagingEmitter;

@interface LLMessagingEmitter ()
@property (nonatomic) dispatch_queue_t serialQueue;
@end

@implementation LLMessagingEmitter
RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("com.localytics.LLShouldDeepLink", DISPATCH_QUEUE_SERIAL);
        messagingEmitter = self;
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"localyticsShouldDeeplink",
             @"localyticsDiyInAppMessage",
             @"localyticsShouldShowInAppMessage",
             @"localyticsShouldDelaySessionStartInAppMessages",
             @"localyticsWillDisplayInAppMessage",
             @"localyticsDidDisplayInAppMessage",
             @"localyticsWillDismissInAppMessage",
             @"localyticsDidDismissInAppMessage",
             @"localyticsDiyPlacesPushNotification",
             @"localyticsShouldShowPlacesPushNotification",
             @"localyticsWillShowPlacesPushNotification"];
}

/**
 send event which are non blocking.

 @param eventName Event Name ex., localyticsDidDisplayInAppMessage
 @param data NSDictionary with key values appropriate to the event
 */
+ (void)sendEvent:(NSString*)eventName withData:(id)data {
    if (messagingEmitter && messagingEmitter.isObserved) {
        [messagingEmitter sendEventWithName:eventName body:data];
    }
}

@end

