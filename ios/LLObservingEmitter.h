//
//  LLObservingEmitter.h
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/26/18.
//  Copyright © 2018 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

@interface LLObservingEmitter : RCTEventEmitter <RCTBridgeModule>
@property (nonatomic, readonly) bool isObserved;
- (void)sendEvent:(NSString*)eventName withData:(id)data;
@end
