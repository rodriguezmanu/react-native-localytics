//
//  LLAnalyticsDelegateBridge.h
//  LLLocalytics
//
//  Created by DeRon Brown on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLObservingEmitter.h"

@interface LLAnalyticsEmitter : LLObservingEmitter
+ (void)sendEvent:(NSString*)eventName withData:(id)data;
@end
