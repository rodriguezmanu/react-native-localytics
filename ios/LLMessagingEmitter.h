//
//  LLMessagingEmitter.h
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/24/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "LLObservingEmitter.h"

@interface LLMessagingEmitter : LLObservingEmitter
+ (void)sendEvent:(NSString*)eventName withData:(id)data;
@end

