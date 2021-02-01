//
//  LLMessagingDelegateBridge.h
//  LLLocalytics
//
//  Created by DeRon Brown on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

@class RCTEventDispatcher;

#import "LLObservingEmitter.h"

@import Localytics;


@interface LLMessagingDelegateBridge : NSObject <LLMessagingDelegate>

@property (nonatomic, strong) NSDictionary *inAppConfig;
@property (nonatomic, strong) NSDictionary *placesConfig;

- (instancetype)init;
- (LLInAppCampaign*) inAppCampaignById:(NSInteger)campaignId;
- (LLPlacesCampaign*) placesCampaignById:(NSInteger)campaignId;
@end
