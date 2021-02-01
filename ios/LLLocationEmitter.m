//
//  LLLocationDelegateBridge.m
//  LLLocalytics
//
//  Created by DeRon Brown on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "LocalyticsPlugin.h"
#import "LLLocationEmitter.h"

static LLLocationEmitter *emitter = nil;

@implementation LLLocationEmitter
RCT_EXPORT_MODULE();

- (instancetype)init {
    self = [super init];
    if (self) {
        emitter = self;
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
    	@"localyticsDidUpdateLocation", 
    	@"localyticsDidUpdateMonitoredGeofences", 
    	@"localyticsDidTriggerRegions"
    	];
}

+ (void)sendEvent:(NSString*)eventName withData:(id)data {
    if (emitter && emitter.isObserved) {
        [emitter sendEventWithName:eventName body:data];
    }
}

@end
