//
//  LLCallToActonEmitter.h
//  LLLocalytics
//

#import "LLObservingEmitter.h"

@interface LLCallToActionEmitter : LLObservingEmitter
+ (void)sendEvent:(NSString*)eventName withData:(id)data;
@end
