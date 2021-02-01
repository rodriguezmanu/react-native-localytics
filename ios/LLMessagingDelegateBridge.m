//
//  LLMessagingDelegateBridge.m
//  LLLocalytics
//
//  Created by DeRon Brown on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//
#import <React/RCTEventDispatcher.h>
#import <React/RCTEventEmitter.h>

#import "LocalyticsPlugin.h"
@import Localytics;
#import "LLMessagingDelegateBridge.h"
#import "LLLocalytics.h"

@import UserNotifications;
#import "LLMessagingEmitter.h"

@class LLInAppCampaign;
@class LLPlacesCampaign;
@class LLInAppConfiguration;

@interface LLMessagingDelegateBridge ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInAppCampaign *> *inAppCampaignCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLPlacesCampaign *> *placesCampaignCache;

@end

@implementation LLMessagingDelegateBridge

- (LLInAppCampaign*) inAppCampaignById:(NSInteger)campaignId {
    return self.inAppCampaignCache[@(campaignId)];
}

- (LLPlacesCampaign*) placesCampaignById:(NSInteger)campaignId {
    return self.placesCampaignCache[@(campaignId)];
}

- (instancetype)init {
    if (self = [super init]) {
        _inAppCampaignCache = [NSMutableDictionary new];
        _placesCampaignCache = [NSMutableDictionary new];
    }

    return self;
}

- (BOOL)localyticsShouldShowInAppMessage:(nonnull LLInAppCampaign *)campaign {
    // Cache campaign
    [self.inAppCampaignCache setObject:campaign forKey:@(campaign.campaignId)];

    BOOL shouldShow = YES;
    if (self.inAppConfig) {

        // Global Suppression
        if (self.inAppConfig[@"shouldShow"]) {
            shouldShow = [self.inAppConfig[@"shouldShow"] boolValue];
        }

        // DIY In-App. This callback will suppress the in-app and emit an event
        // for manually handling
        if (self.inAppConfig[@"diy"] && [self.inAppConfig[@"diy"] boolValue]) {
            NSDictionary *body = @{@"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign]};
            [LLMessagingEmitter sendEvent:@"localyticsDiyInAppMessage" withData:body];
            return NO;
        }
    }

    NSDictionary *body = @{
        @"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign],
        @"shouldShow": @(shouldShow)
    };
    [LLMessagingEmitter sendEvent:@"localyticsShouldShowInAppMessage" withData:body];

    return shouldShow;
}

- (BOOL)localyticsShouldDelaySessionStartInAppMessages {
    BOOL shouldDelay = NO;
    if (self.inAppConfig && self.inAppConfig[@"delaySessionStart"]) {
        shouldDelay = [self.inAppConfig[@"delaySessionStart"] boolValue];
    }

    NSDictionary *body = @{@"shouldDelay": @(shouldDelay)};
    [LLMessagingEmitter sendEvent:@"localyticsShouldDelaySessionStartInAppMessages" withData:body];

    return shouldDelay;
}

- (nonnull LLInAppConfiguration *)localyticsWillDisplayInAppMessage:(nonnull LLInAppCampaign *)campaign withConfiguration:(nonnull LLInAppConfiguration *)configuration {
    if (self.inAppConfig) {
        [LocalyticsPlugin updateInAppConfig:configuration from:(NSDictionary*)self.inAppConfig];
    }

    NSDictionary *body = @{@"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign]};
    [LLMessagingEmitter sendEvent:@"localyticsWillDisplayInAppMessage" withData:body];

    return configuration;
}

- (void)localyticsDidDisplayInAppMessage {
    [LLMessagingEmitter sendEvent:@"localyticsDidDisplayInAppMessage" withData:nil];
}

- (void)localyticsWillDismissInAppMessage {
    [LLMessagingEmitter sendEvent:@"localyticsWillDismissInAppMessage" withData:nil];
}

- (void)localyticsDidDismissInAppMessage {
    [LLMessagingEmitter sendEvent:@"localyticsDidDismissInAppMessage" withData:nil];
}

- (BOOL)localyticsShouldDisplayPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    // Cache campaign
    [self.placesCampaignCache setObject:campaign forKey:@(campaign.campaignId)];

    BOOL shouldShow = YES;
    if (self.placesConfig) {
        // Global Suppression
        if (self.placesConfig[@"shouldShow"]) {
            shouldShow = [self.placesConfig[@"shouldShow"] boolValue];
        }

        // DIY Places. This callback will suppress the Places push and emit an event
        // for manually handling
        if (self.placesConfig[@"diy"] && [self.placesConfig[@"diy"] boolValue]) {
            NSDictionary *body = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
            [LLMessagingEmitter sendEvent:@"localyticsDiyPlacesPushNotification" withData:body];

            return NO;
        }
    }

    NSDictionary *body = @{
        @"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign],
        @"shouldShow": @(shouldShow)
    };
    [LLMessagingEmitter sendEvent:@"localyticsShouldShowPlacesPushNotification" withData:body];

    return shouldShow;
}

- (nonnull UILocalNotification *)localyticsWillDisplayNotification:(nonnull UILocalNotification *)notification forPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    if (self.placesConfig) {
        if (self.placesConfig[@"alertAction"]) {
            notification.alertAction = self.placesConfig[@"alertAction"];
        }
        if (self.placesConfig[@"alertTitle"]) {
            if (@available(iOS 8.2, *)) {
                notification.alertTitle = self.placesConfig[@"alertTitle"];
            } else {
                // Fallback on earlier versions
            }
        }
        if (self.placesConfig[@"hasAction"]) {
            notification.hasAction = [self.placesConfig[@"hasAction"] boolValue];
        }
        if (self.placesConfig[@"alertLaunchImage"]) {
            notification.alertLaunchImage = self.placesConfig[@"alertLaunchImage"];
        }
        if (self.placesConfig[@"category"]) {
            notification.category = self.placesConfig[@"category"];
        }
        if (self.placesConfig[@"applicationIconBadgeNumber"]) {
            notification.applicationIconBadgeNumber = [self.placesConfig[@"applicationIconBadgeNumber"] integerValue];
        }
        if (self.placesConfig[@"soundName"]) {
            notification.soundName = self.placesConfig[@"soundName"];
        }
    }

    NSDictionary *body = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
    [LLMessagingEmitter sendEvent:@"localyticsWillShowPlacesPushNotification" withData:body];

    return notification;
}

- (nonnull UNMutableNotificationContent *)localyticsWillDisplayNotificationContent:(nonnull UNMutableNotificationContent *)notification forPlacesCampaign:(nonnull LLPlacesCampaign *)campaign NS_AVAILABLE_IOS(10_0) {
    if (self.placesConfig) {
        if (self.placesConfig[@"title"]) {
            notification.title = self.placesConfig[@"title"];
        }
        if (self.placesConfig[@"subtitle"]) {
            notification.subtitle = self.placesConfig[@"subtitle"];
        }
        if (self.placesConfig[@"badge"]) {
            notification.badge = @([self.placesConfig[@"badge"] integerValue]);
        }
        if (self.placesConfig[@"sound"]) {
            if (@available(iOS 10.0, *)) {
                notification.sound = [UNNotificationSound soundNamed:self.placesConfig[@"sound"]];
            } else {
                // Fallback on earlier versions
            }
        }
        if (self.placesConfig[@"launchImageName"]) {
            notification.launchImageName = self.placesConfig[@"launchImageName"];
        }
    }

    NSDictionary *body = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
    [LLMessagingEmitter sendEvent:@"localyticsWillShowPlacesPushNotification" withData:body];

    return notification;
}

@end



