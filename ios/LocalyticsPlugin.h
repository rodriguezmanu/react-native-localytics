//
//  LocalyticsPlugin.h
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/23/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@class LLInAppCampaign;
@class LLPlacesCampaign;
@class LLInboxCampaign;
@class LLCustomer;
@class LLInAppConfiguration;
@class LLRegion;
@protocol LLLocationMonitoringDelegate;

@interface LocalyticsPlugin : NSObject
+ (nonnull LocalyticsPlugin*) sharedInstance;

+ (nonnull NSArray<NSString *> *)analyticsEvents;

+ (nullable LLCustomer *)customerFrom:(nonnull NSDictionary *)dict;

+ (void)tagImpressionForInboxCampaignId:(NSInteger)campaignId
                       withActionName:(nonnull NSString*)action;
+ (void)tagImpressionForPushToInboxCampaign:(NSInteger)campaignId success:(BOOL)success;
+ (nonnull NSArray<NSDictionary *> *)getAllInboxCampaigns;
+ (nonnull NSArray<NSDictionary *> *)getDisplayableInboxCampaigns;
+ (void)refreshInboxCampaigns:(nonnull void (^)(NSArray<NSDictionary *> * _Nullable inboxCampaigns))completionBlock;
+ (void)refreshAllInboxCampaigns:(nonnull void (^)(NSArray<NSDictionary *> * _Nullable inboxCampaigns))completionBlock;
+ (NSInteger)inboxUnreadCount;
+ (LLInboxCampaign *)inboxCampaignFromCache:(NSInteger)campaignId;
+ (void)markInboxCampaign:(NSInteger)campaignId asRead:(BOOL)read;
+ (void)deleteInboxCampaign:(NSInteger)campaignId;
+ (void)inboxListItemTapped:(NSInteger)campaignId;

+ (void)setPluginVersion:(nonnull NSString*)version;

+ (nonnull NSString*)inAppMessageDismissButtonLocation;
+ (void)setInAppMessageDismissButtonLocation:(nonnull NSString*)location;
+ (void)updateInAppConfig:(nonnull LLInAppConfiguration*)configuration from:(nonnull NSDictionary*)dict;

+ (void)registerAnalyticsDelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter;
+ (void)registerLocationDelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter;
+ (void)registerCTADelegate:(void (^_Nullable)(NSString*_Nonnull, id _Nonnull))eventEmitter;
+ (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate;

+ (nonnull NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromRegions:(nonnull NSArray<LLRegion *> *)regions;
+ (nonnull NSDictionary<NSString *, NSObject *> *)dictionaryFromInAppCampaign:(nonnull LLInAppCampaign *)campaign;
+ (nonnull NSDictionary<NSString *, NSObject *> *)dictionaryFromPlacesCampaign:(nonnull LLPlacesCampaign *)campaign;


+ (nonnull NSArray<CLRegion *> *)regionsFromDictionaryArray:(nonnull NSArray<NSDictionary *> *)dictArray;
+ (nonnull CLRegion *)regionFromDictionary:(nonnull NSDictionary *)dict;

// We are using int matching NSInteger in LLProfileScope
// The enum would be exported in a later release.
+ (int)profilescopeFrom:(nonnull NSString *)scope;

// We are using int matching NSInteger in LLRegionEvent
// The enum would be exported in a later release.
+ (int)regionEventFrom:(nonnull NSString *)event;

@end



