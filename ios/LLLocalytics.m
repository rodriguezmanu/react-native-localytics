
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
@import CoreLocation;
#import "LLLocalytics.h"
#import "LLLocationEmitter.h"
#import "LLMessagingDelegateBridge.h"
#import "LocalyticsPlugin.h"
@import Localytics;
#import "LLAnalyticsEmitter.h"
#import "LLMessagingEmitter.h"
#import "LLCallToActionEmitter.h"
#import "CLLocation+LocalyticsHelper.h"

@interface RCTConvert (Localytics)
+ (CLLocation*)CLLocation:(id)json;
@end


/**
 * This macro is used for creating converter functions with arbitrary logic. the code should have a return code.
 * it is a copy of the RCT version with return removed before code.
 */
#define LL_RCT_CUSTOM_CONVERTER(type, name, code) \
+ (type)name:(id)json                          \
{                                              \
if (!RCT_DEBUG) {                            \
return code;                               \
} else {                                     \
@try {                                     \
         code;                             \
}                                          \
@catch (__unused NSException *e) {         \
RCTLogConvertError(json, @#type);        \
json = nil;                              \
return nil;                              \
}                                          \
}                                            \
}

@implementation RCTConvert (Localytics)
LL_RCT_CUSTOM_CONVERTER(CLLocation *, CLLocation, json[@"time"] = [RCTConvert NSDate:json[@"time"]];return [CLLocation fromLocalyticsDictionary:json])

@end

@interface LLLocalytics ()

@property (nonatomic, strong) LLMessagingDelegateBridge *messagingDelegateBridge;
/* Based on code from customers and the way promises are processed, it was essential to serialize.
 * It was not critical for common use cases, But queues when run sync can run in the current thread and
 * is extremely performant
 */
@property (nonatomic) dispatch_queue_t returnQueue;
@property (nonatomic) dispatch_queue_t methodSerialQueue;
@end

@implementation LLLocalytics

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (instancetype)init {
    if (self = [super init]) {
        _returnQueue = dispatch_queue_create("com.localytics.JSReturnQueue", DISPATCH_QUEUE_CONCURRENT);
        _methodSerialQueue = dispatch_queue_create("com.localytics.react.methodQueue", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

+(BOOL)requiresMainQueueSetup
{
    return NO;
}

- (dispatch_queue_t)methodQueue {
    return self.methodSerialQueue;
}

#pragma mark - React specific integration

+ (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate {
    [LocalyticsPlugin setLocationMonitoringDelegate:delegate];
}

#pragma mark - Integration

RCT_EXPORT_METHOD(upload) {
    [Localytics upload];
}

RCT_EXPORT_METHOD(openSession) {
    [Localytics openSession];
}

RCT_EXPORT_METHOD(closeSession) {
    [Localytics closeSession];
}

RCT_EXPORT_METHOD(pauseDataUploading:(BOOL)paused) {
    [Localytics pauseDataUploading:paused];
}

#pragma mark - Analytics
RCT_EXPORT_METHOD(setOptedOut:(BOOL)optedOut) {
    [Localytics setOptedOut:optedOut];
}

/**
 * isOptedOut takes a promise that returns a BOOL
 */
RCT_EXPORT_METHOD(isOptedOut:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve(@([Localytics isOptedOut]));
    });
}

RCT_EXPORT_METHOD(setPrivacyOptedOut:(BOOL)optedOut) {
    [Localytics setPrivacyOptedOut:optedOut];
}

RCT_EXPORT_METHOD(isPrivacyOptedOut:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve(@([Localytics isPrivacyOptedOut]));
    });
}

RCT_EXPORT_METHOD(tagEvent:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    if (name.length == 0) {
        RCTLogError(@"invalid nil value for triggerName in dictionary parameter name");
        return;
    }
    NSNumber *customerValueIncrease = params[@"customerValueIncrease"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagEvent:name attributes:attributes customerValueIncrease:customerValueIncrease];
}

RCT_EXPORT_METHOD(tagPurchased:(NSDictionary *)params) {
    NSString *itemName = params[@"itemName"];
    NSString *itemId = params[@"itemId"];
    NSString *itemType = params[@"itemType"];
    NSNumber *itemPrice = params[@"itemPrice"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagPurchased:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
}

RCT_EXPORT_METHOD(tagAddedToCart:(NSDictionary *)params) {
    NSString *itemName = params[@"itemName"];
    NSString *itemId = params[@"itemId"];
    NSString *itemType = params[@"itemType"];
    NSNumber *itemPrice = params[@"itemPrice"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagAddedToCart:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
}

RCT_EXPORT_METHOD(tagStartedCheckout:(NSDictionary *)params) {
    NSNumber *totalPrice = params[@"totalPrice"];
    NSNumber *itemCount = params[@"itemCount"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagStartedCheckout:totalPrice itemCount:itemCount attributes:attributes];
}

RCT_EXPORT_METHOD(tagCompletedCheckout:(NSDictionary *)params) {
    NSNumber *totalPrice = params[@"totalPrice"];
    NSNumber *itemCount = params[@"itemCount"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagCompletedCheckout:totalPrice itemCount:itemCount attributes:attributes];
}

RCT_EXPORT_METHOD(tagContentViewed:(NSDictionary *)params) {
    NSString *contentName = params[@"contentName"];
    NSString *contentId = params[@"contentId"];
    NSString *contentType = params[@"contentType"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagContentViewed:contentName contentId:contentId contentType:contentType attributes:attributes];
}

RCT_EXPORT_METHOD(tagSearched:(NSDictionary *)params) {
    NSString *queryText = params[@"queryText"];
    NSString *contentType = params[@"contentType"];
    NSNumber *resultCount = params[@"resultCount"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagSearched:queryText contentType:contentType resultCount:resultCount attributes:attributes];
}

RCT_EXPORT_METHOD(tagShared:(NSDictionary *)params) {
    NSString *contentName = params[@"contentName"];
    NSString *contentId = params[@"contentId"];
    NSString *contentType = params[@"contentType"];
    NSString *methodName = params[@"methodName"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagShared:contentName contentId:contentId contentType:contentType methodName:methodName attributes:attributes];
}

RCT_EXPORT_METHOD(tagContentRated:(NSDictionary *)params) {
    NSString *contentName = params[@"contentName"];
    NSString *contentId = params[@"contentId"];
    NSString *contentType = params[@"contentType"];
    NSNumber *rating = params[@"rating"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagContentRated:contentName contentId:contentId contentType:contentType rating:rating attributes:attributes];
}

RCT_EXPORT_METHOD(tagCustomerRegistered:(NSDictionary *)params) {
    LLCustomer *customer = [LocalyticsPlugin customerFrom:params[@"customer"]];
    NSString *methodName = params[@"methodName"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagCustomerRegistered:customer methodName:methodName attributes:attributes];
}

RCT_EXPORT_METHOD(tagCustomerLoggedIn:(NSDictionary *)params) {
    LLCustomer *customer = [LocalyticsPlugin customerFrom:params[@"customer"]];
    NSString *methodName = params[@"methodName"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagCustomerLoggedIn:customer methodName:methodName attributes:attributes];
}

RCT_EXPORT_METHOD(tagCustomerLoggedOut:(NSDictionary *)attributes) {
    [Localytics tagCustomerLoggedOut:attributes];
}

RCT_EXPORT_METHOD(tagInvited:(NSDictionary *)params) {
    NSString *methodName = params[@"methodName"];
    NSDictionary *attributes = params[@"attributes"];
    [Localytics tagInvited:methodName attributes:attributes];
}

RCT_EXPORT_METHOD(tagInboxImpression:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    NSString *action = params[@"action"];
    if (action.length != 0){
        [LocalyticsPlugin tagImpressionForInboxCampaignId:campaignId withActionName:action];
    } else {
        RCTLogError(@"Invalid action %@", action);
        return;
    }
}

RCT_EXPORT_METHOD(tagPushToInboxImpression:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    BOOL success = true;
    if (params[@"success"] != nil) {
        success = [params[@"success"] boolValue];
    }
    [LocalyticsPlugin tagImpressionForPushToInboxCampaign:campaignId success:success];
}

RCT_EXPORT_METHOD(tagInAppImpression:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    LLInAppCampaign *campaign = [self.messagingDelegateBridge inAppCampaignById:campaignId];
    NSString *action = params[@"action"];
    if ([@"click" isEqualToString:action]) {
        [Localytics tagImpressionForInAppCampaign:campaign withType:LLImpressionTypeClick];
    } else if ([@"dismiss" isEqualToString:action]) {
        [Localytics tagImpressionForInAppCampaign:campaign withType:LLImpressionTypeDismiss];
    } else {
        [Localytics tagImpressionForInAppCampaign:campaign withCustomAction:action];
    }
}

RCT_EXPORT_METHOD(tagPlacesPushReceived:(nonnull NSNumber *)campaignId) {
    LLPlacesCampaign *campaign = [self.messagingDelegateBridge placesCampaignById:[campaignId unsignedIntegerValue]];;
    if (campaign) {
        [Localytics tagPlacesPushReceived:campaign];
    } else {
        RCTLogWarn(@"Unable to find campaign %@", campaignId);
        return;
    }
}

RCT_EXPORT_METHOD(tagPlacesPushOpened:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    LLPlacesCampaign *campaign = [self.messagingDelegateBridge placesCampaignById:campaignId];
    if (campaign) {
        NSString *actionIdentifier = params[@"action"];
        if (actionIdentifier) {
            [Localytics tagPlacesPushOpened:campaign withActionIdentifier:actionIdentifier];
        } else {
            [Localytics tagPlacesPushOpened:campaign];
        }
    } else {
        RCTLogWarn(@"Unable to find campaign %ld", (long)campaignId);
        return;
    }
}

RCT_EXPORT_METHOD(tagScreen:(NSString*)screenName) {
    if (screenName.length == 0) {
        RCTLogError(@"invalid nil value for triggerName in dictionary parameter name");
        return;
    }
    [Localytics tagScreen:screenName];
}

RCT_EXPORT_METHOD(setCustomDimension:(NSDictionary *)params) {
    NSNumber *dimension = params[@"dimension"];
    if (dimension == nil) {
        RCTLogError(@"invalid value for dimension in dictionary");
        return;
    }
    NSUInteger dimensionIndex = [dimension unsignedIntegerValue];
    if (dimensionIndex > 19) { // Must be 0 to 19.
        RCTLogError(@"invalid dimension value. Valid values are 0 through 19");
        return;
    }
    NSString *value = params[@"value"];
    [Localytics setValue:value forCustomDimension:dimensionIndex];
}

RCT_EXPORT_METHOD(getCustomDimension:(nonnull NSNumber *)dimension resolveBlock:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (dimension == nil || [dimension unsignedIntegerValue] > 19) {
        reject(@"Invalid Argument", @"Invalid dimension argument in getCustomDimension", nil);
        return;
    }
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics valueForCustomDimension:[dimension unsignedIntegerValue]]);
    });
}

RCT_EXPORT_METHOD(setAnalyticsEventsEnabled:(BOOL)enabled) {
    if (enabled) {
        [LocalyticsPlugin registerAnalyticsDelegate:^(NSString * _Nonnull eventName, id _Nonnull object) {
            [LLAnalyticsEmitter sendEvent:eventName withData:object];
        }];
    } else {
        [LocalyticsPlugin registerAnalyticsDelegate:nil];
    }
}

#pragma mark - Profiles

RCT_EXPORT_METHOD(setProfileAttribute:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    id value = params[@"value"];
    if (name.length == 0 || value == nil) {
        RCTLogError(@"required parameters name/value are not valid.");
        return;
    }
    [Localytics setValue:value forProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(addProfileAttributesToSet:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    NSArray *values = params[@"values"];
    if (name.length == 0 || values == nil) {
        RCTLogError(@"required parameters name/value are not valid.");
        return;
    }
    [Localytics addValues:values toSetForProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(removeProfileAttributesFromSet:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    NSArray *values = params[@"values"];
    if (name.length == 0 || values == nil) {
        RCTLogError(@"required parameters name/value are not valid.");
        return;
    }
    [Localytics removeValues:values fromSetForProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(incrementProfileAttribute:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    if (name.length == 0 || params[@"value"] == nil) {
        RCTLogError(@"required parameters name/value are not valid.");
        return;
    }
    NSInteger value = [params[@"value"] integerValue];
    [Localytics incrementValueBy:value forProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(decrementProfileAttribute:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    if (name.length == 0 || params[@"value"] == nil) {
        RCTLogError(@"required parameters name/value are not valid.");
        return;
    }
    NSInteger value = [params[@"value"] integerValue];
    [Localytics decrementValueBy:value forProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(deleteProfileAttribute:(NSDictionary *)params) {
    NSString *name = params[@"name"];
    if (name.length == 0 ) {
        RCTLogError(@"required parameters name are not valid.");
        return;
    }
    [Localytics deleteProfileAttribute:name withScope:[LocalyticsPlugin profilescopeFrom:params[@"scope"]]];
}

RCT_EXPORT_METHOD(setCustomerEmail:(NSString *)email) {
    [Localytics setCustomerEmail:email];
}

RCT_EXPORT_METHOD(setCustomerFirstName:(NSString*)firstName) {
    [Localytics setCustomerFirstName:firstName];
}

RCT_EXPORT_METHOD(setCustomerLastName:(NSString*)lastName) {
    [Localytics setCustomerLastName:lastName];
}

RCT_EXPORT_METHOD(setCustomerFullName:(NSString*)fullName) {
    [Localytics setCustomerFullName:fullName];
}

#pragma mark - Messaging

RCT_EXPORT_METHOD(triggerInAppMessage:(NSDictionary *)params) {
    NSString *triggerName = params[@"triggerName"];
    if (triggerName.length == 0) {
        RCTLogError(@"invalid nil value for identifier in dictionary or string as first Argument");
        return;
    }
    NSDictionary *attributes = params[@"attributes"];
    if (attributes) {
        [Localytics triggerInAppMessage:triggerName withAttributes:attributes];
    }
    else {
        [Localytics triggerInAppMessage:triggerName];
    }
}

RCT_EXPORT_METHOD(triggerInAppMessagesForSessionStart) {
    [Localytics triggerInAppMessagesForSessionStart];
}

RCT_EXPORT_METHOD(dismissCurrentInAppMessage) {
    [Localytics dismissCurrentInAppMessage];
}

RCT_EXPORT_METHOD(forceInAppMessage:(NSDictionary *)params) {
    NSString *campaignId = params[@"campaignId"];
    NSString *creativeId = params[@"creativeId"];
    NSString *localFilePath = params[@"localFilePath"];
    if (localFilePath.length > 0) {
        [Localytics forceInAppMessageDisplay:[NSURL URLWithString:localFilePath]];
    } else if (campaignId.length > 0 && creativeId.length > 0) {
        [Localytics forceInAppMessageDisplay:campaignId forCreative:creativeId];
    } else {
        RCTLogError(@"forceInAppMessage received nil value for expected parameter localFilePath, campaignId, or creativeId");
    }
}

RCT_EXPORT_METHOD(setInAppMessageDismissButtonImageWithName:(NSString *)buttonName) {
    [Localytics setInAppMessageDismissButtonImageWithName:buttonName];
}

RCT_EXPORT_METHOD(setInAppMessageDismissButtonLocation:(NSString *)location) {
    [LocalyticsPlugin setInAppMessageDismissButtonLocation:location];
}

RCT_EXPORT_METHOD(getInAppMessageDismissButtonLocation:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    resolve([LocalyticsPlugin inAppMessageDismissButtonLocation]);
}

RCT_EXPORT_METHOD(setInAppMessageDismissButtonHidden:(BOOL)hidden) {
    [Localytics setInAppMessageDismissButtonHidden:hidden];
}

RCT_EXPORT_METHOD(setInAppMessageConfiguration:(NSDictionary *)config) {
    // Enable messaging events first
    [self setMessagingEventsEnabled:YES];

    self.messagingDelegateBridge.inAppConfig = config;
}

RCT_EXPORT_METHOD(appendAdidToInAppUrls:(BOOL)enabled) {
    [Localytics setInAppAdIdParameterEnabled:enabled];
}

#pragma mark Push
RCT_EXPORT_METHOD(setPushToken:(NSString*)params) {
    if (params.length == 0) {
        RCTLogError(@"The Push Token and  is not a dictionary:token or a string. Push Token Not Registered !!!");
        // Throw an Exception
        return;
    }
    [Localytics setPushToken:[params dataUsingEncoding:NSUTF8StringEncoding]];
}

RCT_EXPORT_METHOD(getPushToken:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics pushToken]);
    });
}

#pragma mark Inbox
RCT_EXPORT_METHOD(getDisplayableInboxCampaigns:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([LocalyticsPlugin getDisplayableInboxCampaigns]);
    });
}

RCT_EXPORT_METHOD(getAllInboxCampaigns:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([LocalyticsPlugin getAllInboxCampaigns]);
    });
}

RCT_EXPORT_METHOD(refreshInboxCampaigns:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        [LocalyticsPlugin refreshInboxCampaigns:resolve];
    });
}

RCT_EXPORT_METHOD(refreshAllInboxCampaigns:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        [LocalyticsPlugin refreshAllInboxCampaigns:resolve];
    });
}

RCT_EXPORT_METHOD(setInboxCampaignRead:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    if (params[@"read"] == nil) {
        RCTLogError(@"Unable to find read in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    BOOL read = [params[@"read"] boolValue];
    [LocalyticsPlugin markInboxCampaign:campaignId asRead:read];
}

RCT_EXPORT_METHOD(getInboxCampaignsUnreadCount:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve(@([LocalyticsPlugin inboxUnreadCount]));
    });
}

RCT_EXPORT_METHOD(deleteInboxCampaign:(NSInteger)campaignId) {
    [LocalyticsPlugin deleteInboxCampaign:campaignId];
}

RCT_EXPORT_METHOD(appendAdidToInboxUrls:(BOOL)enabled) {
    [Localytics setInboxAdIdParameterEnabled:enabled];
}

RCT_EXPORT_METHOD(inboxListItemTapped:(NSDictionary *)params) {
    if (params[@"campaignId"] == nil) {
        RCTLogError(@"Unable to find campaignId in params %@", params);
        return;
    }
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    [LocalyticsPlugin inboxListItemTapped:campaignId];
}

#pragma mark Places
RCT_EXPORT_METHOD(triggerPlacesNotification:(NSDictionary *)params) {
    NSInteger campaignId = [params[@"campaignId"] integerValue];
    NSString *regionId = params[@"regionId"];
    if (regionId.length > 0) {
        [Localytics triggerPlacesNotificationForCampaignId:campaignId regionIdentifier:regionId];
    } else {
        LLPlacesCampaign *campaign = [self.messagingDelegateBridge placesCampaignById:campaignId];
        if (campaign) {
            [Localytics triggerPlacesNotificationForCampaign:campaign];
        } else {
            RCTLogWarn(@"Invalid Campaign Id %ld", (long)campaignId);
        }
    }
}

RCT_EXPORT_METHOD(setPlacesMessageConfiguration:(NSDictionary *)config) {
    // Enable messaging events first
    [self setMessagingEventsEnabled:YES];

    self.messagingDelegateBridge.placesConfig = config;
}

RCT_EXPORT_METHOD(setMessagingEventsEnabled:(BOOL)enabled) {
    if (enabled) {
        if (_messagingDelegateBridge == nil) {
            _messagingDelegateBridge = [[LLMessagingDelegateBridge alloc] init];
        }
        [Localytics setMessagingDelegate:self.messagingDelegateBridge];
    } else {
        [Localytics setMessagingDelegate:nil];
    }
}

#pragma mark - Location

RCT_EXPORT_METHOD(setLocationMonitoringEnabled:(BOOL)enabled) {
    [Localytics setLocationMonitoringEnabled:enabled];
}

RCT_EXPORT_METHOD(persistLocationMonitoring:(BOOL)persist) {
    [Localytics persistLocationMonitoring:persist];
}

RCT_EXPORT_METHOD(getGeofencesToMonitor:(NSDictionary *)params callback:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    double latitude = [params[@"latitude"] doubleValue];
    double longitude = [params[@"longitude"] doubleValue];
    dispatch_async(self.returnQueue, ^{
        NSArray<LLRegion *> *geofences = [Localytics geofencesToMonitor:CLLocationCoordinate2DMake(latitude, longitude)];
        resolve([LocalyticsPlugin dictionaryArrayFromRegions:geofences]);
    });
}

RCT_EXPORT_METHOD(triggerRegion:(NSDictionary *)params) {
    CLRegion* region = [LocalyticsPlugin regionFromDictionary:params[@"region"]];
    if (region == nil) {
        RCTLogError(@"Missing region in triggerRegion");
        return;
    }
    NSString *event = params[@"event"];
    if (event.length == 0) {
        RCTLogError(@"Missing event in triggerRegions");
        return;
    }
    CLLocation *location = [RCTConvert CLLocation:params[@"location"]];
    [Localytics triggerRegion:region withEvent:[LocalyticsPlugin regionEventFrom:event] atLocation:location];
}

RCT_EXPORT_METHOD(triggerRegions:(NSDictionary *)params) {
    NSArray *regions = params[@"regions"];
    if (regions == nil) {
        RCTLogError(@"Missing regions in triggerRegions");
        return;
    }
    NSString *event = params[@"event"];
    if (event.length == 0) {
        RCTLogError(@"Missing event in triggerRegions");
        return;
    }
    CLLocation *location = [RCTConvert CLLocation:params[@"location"]];
    [Localytics triggerRegions:[LocalyticsPlugin regionsFromDictionaryArray:regions] withEvent:[LocalyticsPlugin regionEventFrom:event] atLocation:location];
}

RCT_EXPORT_METHOD(setLocationEventsEnabled:(BOOL)enabled) {
    if (enabled) {
        [LocalyticsPlugin registerLocationDelegate:^(NSString * _Nonnull eventName, id _Nonnull object) {
            [LLLocationEmitter sendEvent:eventName withData:object];
        }];
    } else {
        [LocalyticsPlugin registerLocationDelegate:nil];
    }

}

RCT_EXPORT_METHOD(setCallToActionEventsEnabled:(BOOL)enabled) {
    if (enabled) {
        [LocalyticsPlugin registerCTADelegate:^(NSString * _Nonnull eventName, id _Nonnull object) {
            [LLCallToActionEmitter sendEvent:eventName withData:object];
        }];
    } else {
        [LocalyticsPlugin registerCTADelegate:nil];
    }

}

#pragma mark - User Information

RCT_EXPORT_METHOD(setIdentifier:(NSDictionary *)params) {
    NSString *identifier = params[@"identifier"];
    if (identifier.length == 0) {
        RCTLogError(@"invalid nil value for identifier in dictionary");
        return;
    }
    NSString *value = params[@"value"];
    [Localytics setValue:value forIdentifier:identifier];
}

RCT_EXPORT_METHOD(getIdentifier:(NSString*)identifier resolveBlock:(RCTPromiseResolveBlock)resolve rejectBlock:(RCTPromiseRejectBlock)reject) {
    if (identifier.length == 0) {
        reject(@"getIdentifier", @"invalid nil value for identifier in dictionary or string as first Argument", nil);
        return;
    }
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics valueForIdentifier:identifier]);
    });
}

RCT_EXPORT_METHOD(setCustomerId:(NSString *)customerID) {
    [Localytics setCustomerId:customerID];
}

RCT_EXPORT_METHOD(setCustomerIdWithPrivacyOptedOut:(NSString *)customerId optedOut:(BOOL)optedOut) {
    [Localytics setCustomerId:customerId privacyOptedOut:optedOut];
}

/*
 * getCustomerId takes a promise that returns a string
 */
RCT_EXPORT_METHOD(getCustomerId:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics customerId]);
    });
}

RCT_EXPORT_METHOD(setLocation:(NSDictionary *)location) {
    double latitude = [location[@"latitude"] doubleValue];
    double longitude = [location[@"longitude"] doubleValue];
    [Localytics setLocation:CLLocationCoordinate2DMake(latitude, longitude)];
}

RCT_EXPORT_METHOD(requestAdvertisingIdentifierPrompt) {
    if (@available(iOS 14, *)) {
        [Localytics requestAdvertisingIdentifierPrompt];
    }
}

RCT_EXPORT_METHOD(getAdvertisingIdentifierStatus:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    if (@available(iOS 14, *)) {
        resolve(@([Localytics advertisingIdentifierStatus]));
    } else {
        resolve(@(1));
    }
}

#pragma mark - Developer Options

RCT_EXPORT_METHOD(setOptions:(NSDictionary *)options) {
    [Localytics setOptions:options];
}

RCT_EXPORT_METHOD(didRegisterUserNotificationSettings) {
    [Localytics didRegisterUserNotificationSettings];
}

RCT_EXPORT_METHOD(setLoggingEnabled:(BOOL)enabled) {
    [Localytics setLoggingEnabled:enabled];
}

RCT_EXPORT_METHOD(isLoggingEnabled:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve(@([Localytics isLoggingEnabled]));
    });
}

RCT_EXPORT_METHOD(redirectLogsToDisk:(__unused id)ignoredArgs) {
    [Localytics redirectLoggingToDisk];
}

RCT_EXPORT_METHOD(enableLiveDeviceLogging) {
    [Localytics enableLiveDeviceLogging];
}

RCT_EXPORT_METHOD(setTestModeEnabled:(BOOL)enabled) {
    [Localytics setTestModeEnabled:enabled];
}

RCT_EXPORT_METHOD(isTestModeEnabled:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve(@([Localytics isTestModeEnabled]));
    });
}

RCT_EXPORT_METHOD(getInstallId:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics installId]);
    });
}

RCT_EXPORT_METHOD(getAppKey:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics appKey]);
    });
}

RCT_EXPORT_METHOD(getLibraryVersion:(RCTPromiseResolveBlock)resolve rejecter:(__unused RCTPromiseRejectBlock)reject) {
    dispatch_async(self.returnQueue, ^{
        resolve([Localytics libraryVersion]);
    });
}

@end

#pragma mark Update Plugin version
/*
 *  The static method is called automatically when this module is loaded.
 *  Load ordering is not deterministic.
 */
void myStaticInitMethod(void);

__attribute__((constructor))
void myStaticInitMethod()
{
    [LocalyticsPlugin setPluginVersion:@"RN_3.2.0"];
}
