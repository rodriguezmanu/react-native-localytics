//
//  LLAnalyticsDelegateBridge.m
//  LLLocalytics
//
//  Created by DeRon Brown on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//
@import Localytics;
#import <React/RCTLog.h>
#import "LLAnalyticsEmitter.h"
#import "LocalyticsPlugin.h"

static LLAnalyticsEmitter *analyticsEmitter = nil;

@implementation LLAnalyticsEmitter
RCT_EXPORT_MODULE();
- (instancetype)init {
    self = [super init];
    if (self) {
        analyticsEmitter = self;
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSArray<NSString *> *)supportedEvents {
    return [LocalyticsPlugin analyticsEvents];
}

+ (void)sendEvent:(NSString*)eventName withData:(id)data {
	if (analyticsEmitter && analyticsEmitter.isObserved) {
		[analyticsEmitter sendEventWithName:eventName body:data];
	}
}
@end
