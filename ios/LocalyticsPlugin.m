//
//  LocalyticsPlugin.m
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/23/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

@import CoreLocation;

#import "LocalyticsPlugin.h"
@import Localytics;
#import "LLLocalytics.h"


@interface LLInboxCampaign (LocalyticsPlugin)
- (nonnull NSDictionary *)toDictionary;
@end

@interface LLInAppCampaign (LocalyticsPlugin)
- (nonnull NSDictionary<NSString *, NSObject *> *)toDictionary;
@end

@interface LLGeofence (LocalyticsPlugin)
- (nonnull NSDictionary<NSString *, NSObject *> *)toDictionary;
@end

@interface LLPlacesCampaign (LocalyticsPlugin)
- (nonnull NSDictionary<NSString *, NSObject *> *)toDictionary;
@end

@interface LLInAppConfiguration (LocalyticsPlugin)
- (void)update:(nonnull NSDictionary *)inAppConfig;
@end

typedef void (^_Nullable Emitter)(NSString*_Nonnull, id _Nonnull);

@interface LocalyticsPlugin () <LLAnalyticsDelegate, LLLocationDelegate, LLCallToActionDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInboxCampaign *> *inboxCampaignCache;
@property (nonatomic) dispatch_queue_t inboxCacheSerialQueue;
+ (void)updateInboxCache:(nonnull NSArray<LLInboxCampaign *> *)  campaigns;
+ (void)replaceInboxCache:(nonnull NSArray<LLInboxCampaign *> *) campaigns;
+ (nonnull NSString*)stringWithButtonLocation:(LLInAppMessageDismissButtonLocation) location;
+ (nonnull NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromInboxCampaigns:(nonnull NSArray<LLInboxCampaign *> *)campaigns;

+ (LLInAppMessageDismissButtonLocation)locationFrom:(nullable NSString *)location;

@property (nonatomic, strong) Emitter analyticsEmitter;
@property (nonatomic, strong) Emitter locationEmitter;
@property (nonatomic, strong) Emitter ctaEmitter;
@property (nonatomic, strong) id<LLLocationMonitoringDelegate> locationMonitoringDelegate;

@end

#define EVTNAME_LOCALYTICS_SESSION_WILLOPEN @"localyticsSessionWillOpen"
#define EVTNAME_LOCALYTICS_SESSION_DIDOPEN @"localyticsSessionDidOpen"
#define EVTNAME_LOCALYTICS_SESSION_DIDTAGEVENT @"localyticsDidTagEvent"
#define EVTNAME_LOCALYTICS_SESSION_WILLCLOSE @"localyticsSessionWillClose"

@implementation LocalyticsPlugin
LocalyticsPlugin* shared;

+ (NSArray<NSString *> *)analyticsEvents {
    return @[EVTNAME_LOCALYTICS_SESSION_WILLOPEN,
             EVTNAME_LOCALYTICS_SESSION_DIDOPEN,
             EVTNAME_LOCALYTICS_SESSION_DIDTAGEVENT,
             EVTNAME_LOCALYTICS_SESSION_WILLCLOSE];
}

#pragma mark LLAnalyticsDelegate
- (void)localyticsSessionWillOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume {
    Emitter emitter = shared.analyticsEmitter;
    if (emitter) {
        NSDictionary *body = @{@"isFirst": @(isFirst), @"isUpgrade": @(isUpgrade), @"isResume": @(isResume)};
        emitter(@"localyticsSessionWillOpen", body);
    }
}

- (void)localyticsSessionDidOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume {
    Emitter emitter = shared.analyticsEmitter;
    if (emitter) {
        NSDictionary *body = @{@"isFirst": @(isFirst), @"isUpgrade": @(isUpgrade), @"isResume": @(isResume)};
        emitter(@"localyticsSessionDidOpen", body);
    }
}

- (void)localyticsDidTagEvent:(nonnull NSString *)eventName attributes:(nullable NSDictionary<NSString *,NSString *> *)attributes customerValueIncrease:(nullable NSNumber *)customerValueIncrease {
    Emitter emitter = shared.analyticsEmitter;
    if (emitter) {
        NSDictionary *body = @{@"name": eventName, @"attributes": attributes ?: [NSNull null], @"customerValueIncrease": customerValueIncrease ?: [NSNull null]};
        emitter(@"localyticsDidTagEvent", body);
    }
}

- (void)localyticsSessionWillClose {
    Emitter emitter = shared.analyticsEmitter;
    if (emitter) {
        emitter(@"localyticsSessionWillClose", @{});
    }
}

#pragma mark LLLocationDelegate
- (void)localyticsDidUpdateLocation:(nonnull CLLocation *)location {
    Emitter emitter = shared.locationEmitter;
    if (emitter) {
        NSDictionary *locationDict = @{
                                   @"latitude": @(location.coordinate.latitude),
                                   @"longitude": @(location.coordinate.longitude),
                                   @"altitude": @(location.altitude),
                                   @"time": @(location.timestamp.timeIntervalSince1970),
                                   @"horizontalAccuracy": @(location.horizontalAccuracy),
                                   @"verticalAccuracy": @(location.verticalAccuracy)
                                   };
        NSDictionary *body = @{@"location": locationDict};
        emitter(@"localyticsDidUpdateLocation", body);
    }
}

- (void)localyticsDidUpdateMonitoredRegions:(nonnull NSArray<LLRegion *> *)addedRegions removeRegions:(nonnull NSArray<LLRegion *> *)removedRegions {
    Emitter emitter = shared.locationEmitter;
    if (emitter) {
        NSDictionary *body = @{
                           @"added": [LocalyticsPlugin dictionaryArrayFromRegions:addedRegions],
                           @"removed": [LocalyticsPlugin dictionaryArrayFromRegions:removedRegions],
                           };
        emitter(@"localyticsDidUpdateMonitoredGeofences", body);
    }
}

- (void)localyticsDidTriggerRegions:(nonnull NSArray<LLRegion *> *)regions withEvent:(LLRegionEvent)event {
    Emitter emitter = shared.locationEmitter;
    if (emitter) {
        NSDictionary *body = @{
                           @"regions": [LocalyticsPlugin dictionaryArrayFromRegions:regions],
                           @"event": event == LLRegionEventEnter ? @"enter": @"exit"
                           };
        emitter(@"localyticsDidTriggerRegions", body);
    }
}

#pragma mark LLCallToActionDelegate

- (BOOL)localyticsShouldDeeplink:(nonnull NSURL *)url campaign:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"url": [url absoluteString], @"campaign": campaignDict};
        emitter(@"localyticsShouldDeeplink", body);
    }

    return YES;
}

- (void)localyticsDidOptOut:(BOOL)optedOut campaign:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"optedOut":@(optedOut), @"campaign": campaignDict};
        emitter(@"localyticsDidOptOut", body);
    }
}

- (void)localyticsDidPrivacyOptOut:(BOOL)privacyOptedOut campaign:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"privacyOptedOut":@(privacyOptedOut), @"campaign": campaignDict};
        emitter(@"localyticsDidPrivacyOptOut", body);
    }
}

- (BOOL)localyticsShouldPromptForLocationWhenInUsePermissions:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"campaign": campaignDict};
        emitter(@"localyticsShouldPromptForLocationWhenInUsePermissions", body);
    }
    return YES;
}

- (BOOL)localyticsShouldPromptForLocationAlwaysPermissions:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"campaign": campaignDict};
        emitter(@"localyticsShouldPromptForLocationAlwaysPermissions", body);
    }
    return YES;
}

- (BOOL)localyticsShouldPromptForNotificationPermissions:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"campaign": campaignDict};
        emitter(@"localyticsShouldPromptForNotificationPermissions", body);
    }
    return YES;
}

- (BOOL)localyticsShouldDeeplinkToSettings:(LLCampaignBase *)campaign {
    Emitter emitter = shared.ctaEmitter;
    if (emitter) {
        NSDictionary *campaignDict = [LocalyticsPlugin campaignFromGenericCampaignObject:campaign];
        NSDictionary *body = @{@"campaign": campaignDict};
        emitter(@"localyticsShouldDeeplinkToSettings", body);
    }
    return YES;
}

- (void)requestAlwaysAuthorization:(CLLocationManager *)manager {
    LocalyticsPlugin *sharedPlugin = [LocalyticsPlugin sharedInstance];
    if ([sharedPlugin.locationMonitoringDelegate respondsToSelector:@selector(requestAlwaysAuthorization:)]) {
        [sharedPlugin.locationMonitoringDelegate requestAlwaysAuthorization:manager];
    }
    Emitter emitter = sharedPlugin.ctaEmitter;
    if (emitter) {
        emitter(@"requestAlwaysAuthorization", @{});
    }
}

- (void)requestWhenInUseAuthorization:(CLLocationManager *)manager {
    LocalyticsPlugin *sharedPlugin = [LocalyticsPlugin sharedInstance];
    if ([sharedPlugin.locationMonitoringDelegate respondsToSelector:@selector(requestWhenInUseAuthorization:)]) {
        [sharedPlugin.locationMonitoringDelegate requestWhenInUseAuthorization:manager];
    }
    Emitter emitter = sharedPlugin.ctaEmitter;
    if (emitter) {
        emitter(@"requestWhenInUseAuthorization", @{});
    }
}

#pragma mark Delegate Registerations

+ (void)registerAnalyticsDelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter {
    if (eventEmitter == nil) {
        [Localytics setAnalyticsDelegate:nil];
        [LocalyticsPlugin sharedInstance].analyticsEmitter = nil;
    } else {
        [LocalyticsPlugin sharedInstance].analyticsEmitter = eventEmitter;
        [Localytics setAnalyticsDelegate:[LocalyticsPlugin sharedInstance]];
    }
}

+ (void)registerLocationDelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter {
    if (eventEmitter == nil) {
        [Localytics setLocationDelegate:nil];
        [LocalyticsPlugin sharedInstance].locationEmitter = nil;
    } else {
        [LocalyticsPlugin sharedInstance].locationEmitter = eventEmitter;
        [Localytics setLocationDelegate:[LocalyticsPlugin sharedInstance]];
    }
}

+ (void)registerCTADelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter {
    if (eventEmitter == nil) {
        [Localytics setCallToActionDelegate:nil];
        [LocalyticsPlugin sharedInstance].ctaEmitter = nil;
    } else {
        [LocalyticsPlugin sharedInstance].ctaEmitter = eventEmitter;
        [Localytics setCallToActionDelegate:[LocalyticsPlugin sharedInstance]];
    }   
}

+ (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate {
    LocalyticsPlugin *sharedPlugin = [LocalyticsPlugin sharedInstance];
    sharedPlugin.locationMonitoringDelegate = delegate;
    if (sharedPlugin.ctaEmitter == nil && delegate != nil) {
        //Make sure that if no other delegate was set we still get the callbacks
        [Localytics setCallToActionDelegate:[LocalyticsPlugin sharedInstance]];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _inboxCampaignCache = [NSMutableDictionary new];
        _inboxCacheSerialQueue = dispatch_queue_create("com.localytics.LLShouldDeepLink", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (LocalyticsPlugin *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LocalyticsPlugin alloc] init];
    });
    return shared;
}

#pragma mark API's

+ (void)tagImpressionForInboxCampaignId:(NSInteger)campaignId
                       withActionName:(nonnull NSString*)action {
    LLInboxCampaign *campaign = [LocalyticsPlugin sharedInstance].inboxCampaignCache[@(campaignId)];
    if (campaign) {
        if ([@"click" isEqualToString:action]) {
            [Localytics tagImpressionForInboxCampaign:campaign withType:LLImpressionTypeClick];
        } else if ([@"dismiss" isEqualToString:action]) {
            [Localytics tagImpressionForInboxCampaign:campaign withType:LLImpressionTypeDismiss];
        } else if (action.length == 0){
            [Localytics tagImpressionForInboxCampaign:campaign withCustomAction:action];
        } else {
            NSLog(@"Unable to find action %@", action);
            return;
        }
    } else {
        NSLog(@"Unable to find campaign %ld", (long)campaignId);
        return;
    }
}

+ (void)updateInboxCache:(nonnull NSArray<LLInboxCampaign *> *)  campaigns {
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        // Cache campaigns - Dont clear out here. This is not all campaigns
        for (LLInboxCampaign *campaign in campaigns) {
            [[LocalyticsPlugin sharedInstance].inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }
    });
}

+ (void)replaceInboxCache:(nonnull NSArray<LLInboxCampaign *> *) campaigns {
    // Do an atomic update of campaign cache to avoid issues when accessing from multiple queues.
    NSMutableDictionary* newCache = [NSMutableDictionary new];
    for (LLInboxCampaign *campaign in campaigns) {
        [newCache setObject:campaign forKey:@(campaign.campaignId)];
    }
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        [LocalyticsPlugin sharedInstance].inboxCampaignCache = newCache;
    });
}

+ (void)tagImpressionForPushToInboxCampaign:(NSInteger)campaignId success:(BOOL)success {
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        LLInboxCampaign* campaign = [LocalyticsPlugin sharedInstance].inboxCampaignCache[@(campaignId)];
        if (campaign) {
            [Localytics tagImpressionForPushToInboxCampaign:campaign success:success];
        }
    });
}

+ (NSInteger)inboxUnreadCount {
    __block NSInteger count;
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        count = [Localytics inboxCampaignsUnreadCount];
    });
    return count;
}

+ (LLInboxCampaign *)inboxCampaignFromCache:(NSInteger)campaignId {
    return [LocalyticsPlugin sharedInstance].inboxCampaignCache[@(campaignId)];
}

+ (void)markInboxCampaign:(NSInteger)campaignId asRead:(BOOL)read {
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        LLInboxCampaign* campaign = [LocalyticsPlugin sharedInstance].inboxCampaignCache[@(campaignId)];
        if (campaign==nil) {
            NSLog(@"No campaign found for id :%ld", (long)campaignId);
        }
        [Localytics setInboxCampaign:campaign asRead:read];
    });
}

+ (void)deleteInboxCampaign:(NSInteger)campaignId {
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        LLInboxCampaign *campaign = LocalyticsPlugin.sharedInstance.inboxCampaignCache[@(campaignId)];
        if (campaign==nil) {
            NSLog(@"No campaign found for id :%ld", (long)campaignId);
        } else {
            [Localytics deleteInboxCampaign:campaign];
            [[LocalyticsPlugin sharedInstance].inboxCampaignCache removeObjectForKey:@(campaignId)];
        }
        
    });   
}

+ (void)inboxListItemTapped:(NSInteger)campaignId {
    dispatch_sync([LocalyticsPlugin sharedInstance].inboxCacheSerialQueue, ^{
        LLInboxCampaign *campaign = LocalyticsPlugin.sharedInstance.inboxCampaignCache[@(campaignId)];
        if (campaign==nil) {
            NSLog(@"No campaign found for id :%ld", (long)campaignId);
        } else {
            [Localytics inboxListItemTapped:campaign];
        }
        
    });
}

/**
 Set Plugin Version. Has effect only first time.

 @param version version to set for Plugin.
 */
+ (void)setPluginVersion:(nonnull NSString*)version {
    [Localytics setOptions:@{@"plugin_library":version}];
}

+ (NSString*)stringWithButtonLocation:(LLInAppMessageDismissButtonLocation) location {
    switch (location) {
        case LLInAppMessageDismissButtonLocationLeft:
            return @"left";
            break;
        case LLInAppMessageDismissButtonLocationRight:
            return @"right";
    }
}

+ (NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromInboxCampaigns:(NSArray<LLInboxCampaign *> *)campaigns {
    NSMutableArray *array = [NSMutableArray new];
    for (LLInboxCampaign *campaign in campaigns) {
        [array addObject:[campaign toDictionary]];
    }
    
    return array;
}

+ (NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromRegions:(NSArray<LLRegion *> *)regions {
    NSMutableArray *array = [NSMutableArray new];
    for (LLRegion *region in regions) {
        if ([region isKindOfClass:[LLGeofence class]]) {
            LLGeofence *geofence = (LLGeofence*)region;
            [array addObject:[geofence toDictionary]];
        }
    }
    
    return [array copy];
}

+ (NSArray<CLRegion *> *)regionsFromDictionaryArray:(NSArray<NSDictionary *> *)dictArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSDictionary *dict in dictArray) {
        [array addObject:[LocalyticsPlugin regionFromDictionary:dict]];
    }
    
    return [array copy];
}

+ (nonnull NSArray<NSDictionary *> *)getAllInboxCampaigns {
    NSArray<LLInboxCampaign *> *inboxCampaigns = [Localytics allInboxCampaigns];
    [LocalyticsPlugin replaceInboxCache:inboxCampaigns];
    return [LocalyticsPlugin dictionaryArrayFromInboxCampaigns:inboxCampaigns];
}

+ (nonnull NSArray<NSDictionary *> *)getDisplayableInboxCampaigns {
    NSArray<LLInboxCampaign *> *inboxCampaigns = [Localytics displayableInboxCampaigns];
    [LocalyticsPlugin updateInboxCache:inboxCampaigns];
    return [LocalyticsPlugin dictionaryArrayFromInboxCampaigns:inboxCampaigns];   
}

+ (void)refreshAllInboxCampaigns:(nonnull void (^)(NSArray<NSDictionary *> * _Nullable inboxCampaigns))completionBlock {
    [Localytics refreshAllInboxCampaigns:^(NSArray<LLInboxCampaign *> *allCampaigns) {
        [LocalyticsPlugin replaceInboxCache:allCampaigns];
        completionBlock([LocalyticsPlugin dictionaryArrayFromInboxCampaigns:allCampaigns]);
    }];
}

+ (void)refreshInboxCampaigns:(nonnull void (^)(NSArray<NSDictionary *> * _Nullable inboxCampaigns))completionBlock {
    [Localytics refreshInboxCampaigns:^(NSArray<LLInboxCampaign *> *inboxCampaigns) {
        [LocalyticsPlugin updateInboxCache:inboxCampaigns];
        
        completionBlock( [LocalyticsPlugin dictionaryArrayFromInboxCampaigns:inboxCampaigns]);
    }];
}

+ (nonnull NSString*)inAppMessageDismissButtonLocation {
    LLInAppMessageDismissButtonLocation location = [Localytics inAppMessageDismissButtonLocation];
    return [LocalyticsPlugin stringWithButtonLocation:location];
}

+ (void)setInAppMessageDismissButtonLocation:(nonnull NSString*)location {
    [Localytics setInAppMessageDismissButtonLocation:[LocalyticsPlugin locationFrom:location]];
}

+ (void)updateInAppConfig:(LLInAppConfiguration*)configuration from:(NSDictionary*)dict {
    [configuration update:dict];
}

+ (LLInAppMessageDismissButtonLocation)locationFrom:(nullable NSString *)location {
    // TODO FIX ME Case insensitive compare.
    if ([@"right" caseInsensitiveCompare:location] == NSOrderedSame) {
        return LLInAppMessageDismissButtonLocationRight;
    } else {
        return LLInAppMessageDismissButtonLocationLeft;
    }
}

#pragma mark Conversions - Conversion Arguments need to validate input for nonnull
+ (CLRegion *)regionFromDictionary:(NSDictionary *)dict {
    if (dict == nil || dict[@"uniqueId"] == nil ) {
        return nil;
    }
    return [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0)
                                             radius:1
                                         identifier:dict[@"uniqueId"]];
}

+ (LLCustomer *)customerFrom:(NSDictionary *)dict {
    if (dict) {
        return [LLCustomer customerWithBlock:^(LLCustomerBuilder* builder) {
            builder.customerId = dict[@"customerId"];
            builder.firstName = dict[@"firstName"];
            builder.lastName = dict[@"lastName"];
            builder.fullName = dict[@"fullName"];
            builder.emailAddress = dict[@"emailAddress"];
        }];
    }
    return nil;
}

+ (int)profilescopeFrom:(NSString *)scope {
    if ([@"org" caseInsensitiveCompare:scope] == NSOrderedSame) {
        return LLProfileScopeOrganization;
    } else { // App is default.
        return LLProfileScopeApplication;
    }
}

+ (int)regionEventFrom:(NSString *)event {
    if ([@"enter" caseInsensitiveCompare:event] == NSOrderedSame) {
        return LLRegionEventEnter;
    } else { // Default Exit backward compatibility
        return LLRegionEventExit;
    }
}

+ (nonnull NSDictionary<NSString *, NSObject *> *)dictionaryFromInAppCampaign:(nonnull LLInAppCampaign *)campaign {
    return [campaign toDictionary];
}

+ (nonnull NSDictionary<NSString *, NSObject *> *)dictionaryFromPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    return [campaign toDictionary];
}

+(nullable NSDictionary<NSString *, NSObject *> *)campaignFromGenericCampaignObject:(LLCampaignBase *)campaign {
    if ([campaign isKindOfClass:[LLInAppCampaign class]]) {
        return [LocalyticsPlugin dictionaryFromInAppCampaign:(LLInAppCampaign *) campaign];
    } else if ([campaign isKindOfClass:[LLInboxCampaign class]]) {
        return [((LLInboxCampaign *) campaign) toDictionary];
    } else if ([campaign isKindOfClass:[LLPlacesCampaign class]]) {
        return [LocalyticsPlugin dictionaryFromPlacesCampaign:(LLPlacesCampaign *) campaign];
    }
    return nil;
}
@end

@implementation LLInboxCampaign (LocalyticsPlugin)
- (nonnull NSDictionary *)toDictionary {
    return @{
             // LLCampaignBase
             @"campaignId": @(self.campaignId),
             @"name": self.name,
             @"attributes": self.attributes ?: [NSNull null],
             
             // LLWebViewCampaign
             @"creativeFilePath": self.creativeFilePath ?: [NSNull null],
             
             // LLInboxCampaign
             @"read": @(self.isRead),
             @"title": self.titleText ?: [NSNull null],
             @"summary": self.summaryText ?: [NSNull null],
             @"thumbnailUrl": [self.thumbnailUrl absoluteString] ?: @"",
             @"hasCreative": @(self.hasCreative),
             @"sortOrder": @(self.sortOrder),
             @"receivedDate": @(self.receivedDate),
             @"deepLinkURL":self.deepLinkURL.absoluteString ?: @"",
             @"pushToInboxCampaign":@(self.isPushToInboxCampaign),
             @"deleted":@(self.isDeleted),
             @"videoConversionPercentage": @(self.videoConversionPercentage)
             };
}
@end

@implementation LLInAppCampaign (LocalyticsPlugin)
- (NSDictionary<NSString *, NSObject *> *)toDictionary {
    LLInAppCampaign *campaign =  self;
    NSString *typeString = @"";
    switch (campaign.type) {
        case LLInAppMessageTypeTop:
            typeString = @"top";
            break;
        case LLInAppMessageTypeBottom:
            typeString = @"bottom";
            break;
        case LLInAppMessageTypeCenter:
            typeString = @"center";
            break;
        case LLInAppMessageTypeFull:
            typeString = @"full";
            break;
    }
    NSString* buttonLocation = [LocalyticsPlugin stringWithButtonLocation:campaign.dismissButtonLocation];
    return @{
             // LLCampaignBase
             @"campaignId": @(campaign.campaignId),
             @"name": campaign.name,
             @"attributes": campaign.attributes ?: [NSNull null],
             
             // LLWebViewCampaign
             @"creativeFilePath": campaign.creativeFilePath ?: [NSNull null],
             
             // LLInAppCampaign
             @"type": typeString,
             @"isResponsive": @(campaign.isResponsive),
             @"aspectRatio": @(campaign.aspectRatio),
             @"offset": @(campaign.offset),
             @"backgroundAlpha": @(campaign.backgroundAlpha),
             @"dismissButtonHidden": @(campaign.isDismissButtonHidden),
             @"dismissButtonLocation": buttonLocation,
             @"eventName": campaign.eventName,
             @"eventAttributes": campaign.eventAttributes ?: [NSNull null]
             };
}
@end

@implementation LLGeofence (LocalyticsPlugin)
- (NSDictionary<NSString *, NSObject *> *)toDictionary {
    LLGeofence *geofence = self;
    return @{
             @"uniqueId": geofence.region.identifier,
             @"latitude": @(geofence.region.center.latitude),
             @"longitude": @(geofence.region.center.longitude),
             @"name": geofence.name ?: [NSNull null],
             @"attributes": geofence.attributes ?: [NSNull null]
             };
}
@end

@implementation LLPlacesCampaign (LocalyticsPlugin)
- (NSDictionary<NSString *, NSObject *> *)toDictionary {
    LLPlacesCampaign *campaign = self;
    return @{
             // LLCampaignBase
             @"campaignId": @(campaign.campaignId),
             @"name": campaign.name,
             @"attributes": campaign.attributes ?: [NSNull null],
             
             // LLPlacesCampaign
             @"message": campaign.message,
             @"soundFilename": campaign.soundFilename ?: [NSNull null],
             @"region": [((LLGeofence *)campaign.region) toDictionary],
             @"triggerEvent": campaign.event == LLRegionEventEnter ? @"enter" : @"exit",
             @"category": self.category,
             @"attachmentURL":self.attachmentURL,
             @"attachmentType":self.attachmentType
             };
}
@end

@implementation LLInAppConfiguration (LocalyticsPlugin)
- (void)update:(nonnull NSDictionary *)inAppConfig {
    if (inAppConfig[@"dismissButtonLocation"]) {
        self.dismissButtonLocation = [LocalyticsPlugin locationFrom:inAppConfig[@"dismissButtonLocation"]];
    }
    if (inAppConfig[@"dismissButtonHidden"]) {
        self.dismissButtonHidden = [inAppConfig[@"dismissButtonHidden"] boolValue];
    }
    if (inAppConfig[@"dismissButtonImageName"]) {
        [self setDismissButtonImageWithName:inAppConfig[@"dismissButtonImageName"]];
    }
    if (inAppConfig[@"aspectRatio"]) {
        self.aspectRatio = [inAppConfig[@"aspectRatio"] floatValue];
    }
    if (inAppConfig[@"offset"]) {
        self.offset = [inAppConfig[@"offset"] floatValue];
    }
    if (inAppConfig[@"backgroundAlpha"]) {
        self.backgroundAlpha = [inAppConfig[@"backgroundAlpha"] floatValue];
    }
    if (inAppConfig[@"autoHideHomeScreenIndicator"]) {
        self.autoHideHomeScreenIndicator = [inAppConfig[@"autoHideHomeScreenIndicator"] boolValue]; 
    }
    if (inAppConfig[@"notchFullScreen"]) {
        self.notchFullScreen = [inAppConfig[@"notchFullScreen"] boolValue]; 
    }
    if (inAppConfig[@"videoConversionPercentage"]) {
        self.videoConversionPercentage = [inAppConfig[@"videoConversionPercentage"] floatValue];
    }
}
@end


