
#if __has_include(<React/RCTBridgeModule.h>)
  #import <React/RCTBridgeModule.h>
#else
  #import "RCTBridgeModule.h"
#endif
#import <CoreLocation/CoreLocation.h>
@protocol LLLocationMonitoringDelegate;

typedef NS_ENUM(NSUInteger, LLInAppMessageDismissButtonLocation);

@interface LLLocalytics : NSObject <RCTBridgeModule>

+ (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate;

@end

@protocol LLLocationMonitoringDelegate <NSObject>
@optional

/**
 * Callback to request the Always Authorization. Localytics setLocationMonitoringEnabled API requires implementation of this callback.
 * @param locationManager CLLocationManager instance to request Authorization
 @Discussion
 * Sample Implementation\: [locationManager requestAlwaysAuthorization];
 
 @Note Apple requires application developers to be aware and request permissions needed by SDK.
 @Version SDK 5.3
 */
- (void)requestAlwaysAuthorization:(nonnull CLLocationManager *)locationManager;

/**
 * Callback to request When in Use Authorization.
 @param locationManager CLLocationManager instance to request Authorization
 *
 * Sample Implementation \: [locationManager requestWhenInUseAuthorization];
 @Note Apple requires application developers to be aware and request permissions needed by SDK.
 @Version SDK 5.3
 */
- (void)requestWhenInUseAuthorization:(nonnull CLLocationManager *)locationManager;

@end
