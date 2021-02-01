//
//  LLObservingEmitter.m
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/26/18.
//  Copyright © 2018 Localytics. All rights reserved.
//

#import "LLObservingEmitter.h"

@interface LLObservingEmitter ()
@property (nonatomic, readwrite) bool isObserved;
@end

@implementation LLObservingEmitter
- (void)sendEvent:(NSString*)eventName withData:(id)data {
    [self sendEventWithName:eventName body:data];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[];
}

- (void)startObserving {
    self.isObserved = true;
}

- (void)stopObserving {
    self.isObserved = false;
}

@end
